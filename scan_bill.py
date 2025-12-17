#!/usr/bin/env python3
"""
智能账单扫描工具
用法: python3 scan_bill.py <图片路径> [选项]
支持单个订单和订单列表

默认模式（推荐）:
  - 使用 qwen2.5:3b 模型，识别最精准
  - 适合复杂账单（如组合商品、多项明细）
  - 速度: ~6-8秒

优化选项:
  --fast            快速模式（速度优先，适合简单账单）
                    使用 qwen2.5:1.5b 小模型，速度 ~3-4秒
                    注意: 复杂账单可能商品价格不准确
  --model <模型>    指定 LLM 模型（默认: qwen2.5:3b）
  --no-angle        关闭 OCR 角度检测（图片方向正确时）
  --clean           清理 OCR 文本（移除 UI 元素，提升 5-10% 速度）
  --concurrent      启用并发解析（订单列表）
"""

import sys
import os
import time
import logging
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# 设置日志级别为 WARNING，隐藏 INFO 日志
logging.basicConfig(level=logging.WARNING)

sys.path.insert(0, os.path.dirname(__file__))

from src.ocr import RapidOCREngine, clean_ocr_text
from src.llm import OllamaEngine
from src.parser.smart_parser import SmartParser
from src.parser.multi_order_parser import MultiOrderParser
from src.parser.fast_parser import FastBillParser
from src.parser.bank_parser import BankStatementParser


def parse_single_order(order_block, llm_engine, is_bank_statement=False, skip_items=False):
    """解析单个订单（用于并发）"""
    if is_bank_statement:
        parser = BankStatementParser()
        result = parser.parse(order_block.text)
    else:
        parser = FastBillParser(llm_engine, skip_items=skip_items)
        result = parser.parse(order_block.text)

    # 添加状态信息
    if result.success and result.invoice:
        if not result.invoice.remarks:
            result.invoice.remarks = f"订单状态: {order_block.status}"
        else:
            result.invoice.remarks += f" | 订单状态: {order_block.status}"

    return result, order_block.status


def scan_bill(image_path: str, model: str = "qwen2.5:3b",
              use_angle_cls: bool = True, concurrent: bool = False,
              clean_text: bool = False, format_text: bool = False,
              skip_items: bool = False):
    """快速扫描账单"""

    # 检查文件
    if not Path(image_path).exists():
        print(f"错误: 文件不存在 - {image_path}")
        return

    print(f"\n扫描账单: {image_path}")
    print("-" * 60)

    # 记录时间
    times = {}
    total_start = time.time()

    # OCR 提取
    print("[ 1/5 ] OCR 文本提取...", end=" ", flush=True)
    t = time.time()
    ocr = RapidOCREngine(use_angle_cls=use_angle_cls, print_verbose=False)
    ocr_result = ocr.extract_text(image_path)
    times['ocr'] = time.time() - t

    if not ocr_result.success:
        print(f"✗ 失败: {ocr_result.error_message}")
        return

    # 文本清理/格式化（可选）
    if clean_text or format_text:
        original_len = len(ocr_result.text)
        ocr_result.text = clean_ocr_text(ocr_result.text, format_text=format_text)
        cleaned_len = len(ocr_result.text)
        reduction = (original_len - cleaned_len) / original_len * 100
        format_tag = "+格式化" if format_text else ""
        print(f"✓ ({times['ocr']:.2f}s, {len(ocr_result.lines)}行, {ocr_result.avg_score:.1%}, 文本↓{reduction:.0f}%{format_tag})")
    else:
        print(f"✓ ({times['ocr']:.2f}s, {len(ocr_result.lines)}行, {ocr_result.avg_score:.1%})")

    # 初始化 LLM
    print("[ 2/5 ] 初始化 LLM...", end=" ", flush=True)
    t = time.time()
    llm = OllamaEngine(model_name=model, temperature=0.0, max_tokens=512)
    times['init'] = time.time() - t
    print(f"✓ ({times['init']:.2f}s)")

    # 检测是否是订单列表
    print("[ 3/5 ] 检测订单类型...", end=" ", flush=True)
    t = time.time()
    multi_parser = MultiOrderParser(llm, skip_items=skip_items)
    is_list, list_conf = multi_parser.is_order_list(ocr_result.text)
    times['detect_type'] = time.time() - t

    if is_list:
        print(f"✓ ({times['detect_type']:.2f}s) -> 订单列表 ({list_conf:.0%})")
    else:
        print(f"✓ ({times['detect_type']:.2f}s) -> 单个订单")

    # 解析账单
    if is_list:
        # 订单列表处理
        print("[ 4/5 ] 分离订单...", end=" ", flush=True)
        t = time.time()
        order_blocks = multi_parser.split_orders(ocr_result.text)
        times['split'] = time.time() - t
        print(f"✓ ({times['split']:.2f}s) -> {len(order_blocks)}个订单")

        print("[ 5/5 ] 解析订单列表...", end=" ", flush=True)
        t = time.time()

        # 检测是否是银行流水
        is_bank_statement = multi_parser._is_bank_statement_list(ocr_result.text)

        if concurrent and len(order_blocks) > 1:
            # 并发解析
            results = []
            stats = {
                'total_orders': len(order_blocks),
                'completed': 0,
                'cancelled': 0,
                'in_progress': 0,
                'other': 0,
            }

            with ThreadPoolExecutor(max_workers=min(len(order_blocks), 4)) as executor:
                futures = {
                    executor.submit(parse_single_order, block, llm, is_bank_statement, skip_items): i
                    for i, block in enumerate(order_blocks)
                }

                temp_results = [None] * len(order_blocks)
                for future in as_completed(futures):
                    idx = futures[future]
                    result, status = future.result()
                    temp_results[idx] = (result, status)

                for result, status in temp_results:
                    results.append(result)
                    if status == '已完成':
                        stats['completed'] += 1
                    elif status == '已取消':
                        stats['cancelled'] += 1
                    elif status in ['进行中', '待支付', '待发货', '待收货']:
                        stats['in_progress'] += 1
                    else:
                        stats['other'] += 1
        else:
            # 串行解析
            results, stats = multi_parser.parse_order_list(ocr_result.text)

        times['parse'] = time.time() - t
        mode_str = "并发" if concurrent and len(order_blocks) > 1 else "串行"
        print(f"✓ ({times['parse']:.2f}s, {mode_str})")

        times['total'] = time.time() - total_start

        # 显示订单列表结果
        display_order_list_results(results, stats, times)

    else:
        # 单个订单处理
        print("[ 4/5 ] 检测账单类型...", end=" ", flush=True)
        t = time.time()
        parser = SmartParser(llm, skip_items=skip_items)
        bill_type, conf, mode = parser.detect_type_only(ocr_result.text)
        times['detect'] = time.time() - t
        print(f"✓ ({times['detect']:.2f}s) -> {bill_type} ({conf:.0%}, {mode})")

        print("[ 5/5 ] 解析账单信息...", end=" ", flush=True)
        t = time.time()
        result = parser.parse(ocr_result.text)
        times['parse'] = time.time() - t

        if not result.success:
            print(f"✗ 失败: {result.error_message}")
            return
        print(f"✓ ({times['parse']:.2f}s, {result.confidence:.0%})")

        times['total'] = time.time() - total_start

        # 显示单个订单结果
        display_single_order_result(result, times)


def display_single_order_result(result, times):
    """显示单个订单结果"""
    print("\n" + "=" * 60)
    print(" 识别结果")
    print("=" * 60)

    inv = result.invoice

    if inv.invoice_type:
        print(f"📋 类型: {inv.invoice_type}")
    if inv.invoice_number:
        print(f"🔢 编号: {inv.invoice_number}")
    if inv.invoice_date:
        print(f"📅 日期: {inv.invoice_date}")
    if inv.seller_name:
        print(f"🏢 商家: {inv.seller_name}")
    if inv.buyer_name:
        print(f"👤 客户: {inv.buyer_name}")
    if inv.buyer_phone:
        print(f"📞 电话: {inv.buyer_phone}")

    if inv.items:
        print(f"\n📦 明细 ({len(inv.items)}项):")
        for i, item in enumerate(inv.items[:5], 1):
            qty = f" x{int(item.quantity)}" if item.quantity else ""
            amt = f"¥{item.amount:.2f}" if item.amount else ""
            print(f"  {i}. {item.name}{qty} {amt}")
        if len(inv.items) > 5:
            print(f"  ... 还有 {len(inv.items) - 5} 项")

    if inv.total_amount:
        print(f"\n💰 总计: ¥{inv.total_amount:.2f}")

    # 性能统计
    print("\n" + "=" * 60)
    print(" 性能统计")
    print("=" * 60)
    print(f"OCR 提取:    {times['ocr']:>6.2f}s  ({times['ocr']/times['total']*100:>5.1f}%)")
    print(f"LLM 初始化:  {times['init']:>6.2f}s  ({times['init']/times['total']*100:>5.1f}%)")
    print(f"类型检测:    {times.get('detect', 0):>6.2f}s  ({times.get('detect', 0)/times['total']*100:>5.1f}%)")
    print(f"账单解析:    {times['parse']:>6.2f}s  ({times['parse']/times['total']*100:>5.1f}%)")
    print("-" * 60)
    print(f"总计:       {times['total']:>6.2f}s")
    print("=" * 60 + "\n")


def display_order_list_results(results, stats, times):
    """显示订单列表结果"""
    print("\n" + "=" * 60)
    print(" 订单列表识别结果")
    print("=" * 60)

    print(f"\n📊 统计信息:")
    print(f"  总订单数: {stats['total_orders']}")
    print(f"  已完成: {stats['completed']}")
    print(f"  已取消: {stats['cancelled']}")
    print(f"  进行中: {stats['in_progress']}")
    if stats['other'] > 0:
        print(f"  其他: {stats['other']}")

    print(f"\n📦 订单明细:")
    print("-" * 60)

    total_amount = 0
    for i, result in enumerate(results, 1):
        if not result.success:
            print(f"\n订单 {i}: ✗ 解析失败")
            continue

        inv = result.invoice
        status_emoji = "✓" if "已完成" in (inv.remarks or "") else "✗" if "已取消" in (inv.remarks or "") else "◷"

        print(f"\n订单 {i}: {status_emoji}")

        if inv.seller_name:
            print(f"  🏢 {inv.seller_name}")

        if inv.items:
            print(f"  商品: {len(inv.items)}件")
            for item in inv.items[:3]:
                qty = f" x{int(item.quantity)}" if item.quantity else ""
                print(f"    • {item.name}{qty}")
            if len(inv.items) > 3:
                print(f"    ... 还有 {len(inv.items) - 3} 项")

        if inv.total_amount:
            print(f"  💰 金额: ¥{inv.total_amount:.2f}")
            # 只统计已完成的订单
            if "已完成" in (inv.remarks or ""):
                total_amount += inv.total_amount

        if inv.remarks:
            print(f"  📝 {inv.remarks}")

    if total_amount > 0:
        print("\n" + "-" * 60)
        print(f"已完成订单总计: ¥{total_amount:.2f}")

    # 性能统计
    print("\n" + "=" * 60)
    print(" 性能统计")
    print("=" * 60)
    print(f"OCR 提取:    {times['ocr']:>6.2f}s  ({times['ocr']/times['total']*100:>5.1f}%)")
    print(f"LLM 初始化:  {times['init']:>6.2f}s  ({times['init']/times['total']*100:>5.1f}%)")
    print(f"类型检测:    {times['detect_type']:>6.2f}s  ({times['detect_type']/times['total']*100:>5.1f}%)")
    print(f"订单分离:    {times['split']:>6.2f}s  ({times['split']/times['total']*100:>5.1f}%)")
    print(f"订单解析:    {times['parse']:>6.2f}s  ({times['parse']/times['total']*100:>5.1f}%)")
    print("-" * 60)
    print(f"总计:       {times['total']:>6.2f}s")
    print("=" * 60 + "\n")


def main():
    if len(sys.argv) < 2 or '--help' in sys.argv or '-h' in sys.argv:
        print("智能账单扫描工具 - KAPI")
        print("=" * 60)
        print("\n用法: python3 scan_bill.py <图片路径> [选项]")
        print("\n📌 推荐用法（标准模式 - 最精准）:")
        print("  python3 scan_bill.py bill.jpg")
        print("  - 使用 qwen2.5:3b 模型")
        print("  - 适合复杂账单（组合商品、多项明细）")
        print("  - 速度: ~6-8秒")
        print("\n⚡ 快速模式（速度优先）:")
        print("  python3 scan_bill.py bill.jpg --fast")
        print("  - 使用 qwen2.5:1.5b 小模型")
        print("  - 速度: ~3-4秒")
        print("  - 注意: 复杂账单的商品价格可能不准确")
        print("\n选项:")
        print("  --fast            快速模式（速度优先，适合简单账单）")
        print("  --model <模型>    指定 LLM 模型（默认: qwen2.5:3b）")
        print("  --no-angle        关闭 OCR 角度检测（图片方向正确时更快）")
        print("  --clean           清理 OCR 文本（移除 UI 元素，提升 5-10% 速度）")
        print("  --format          格式化 OCR 文本（合并商品信息，提升 20-30% 速度）⚠️ 可能漏项")
        print("  --no-items        不识别商品明细（仅总金额，提升 50-60% 速度）⚡")
        print("  --concurrent      启用并发解析订单列表")
        print("\n高级示例:")
        print("  python3 scan_bill.py invoice.png --model qwen2.5:7b")
        print("  python3 scan_bill.py list.jpg --fast --concurrent")
        print("  python3 scan_bill.py order.jpg --no-angle --clean  # 准确+快速 ✓")
        print("  python3 scan_bill.py order.jpg --no-angle --format  # 极速（可能漏项）")
        print("  python3 scan_bill.py order.jpg --no-angle --no-items  # 只要总金额 ⚡")
        print("\n特性:")
        print("  ✓ 自动识别单个订单或订单列表")
        print("  ✓ 智能分离和解析多个订单")
        print("  ✓ 银行流水瞬间识别（无需 LLM）")
        print("  ✓ 支持 20+ 个餐饮/电商平台")
        sys.exit(1)

    # 解析参数
    args = sys.argv[1:]
    image = args[0]

    # 默认配置
    model = "qwen2.5:3b"
    use_angle_cls = True
    concurrent = False

    # 快速模式
    if '--fast' in args:
        model = "qwen2.5:1.5b"
        use_angle_cls = False
        concurrent = True
        args.remove('--fast')

    # 自定义模型
    if '--model' in args:
        idx = args.index('--model')
        if idx + 1 < len(args):
            model = args[idx + 1]

    # 并发模式
    if '--concurrent' in args:
        concurrent = True

    # 关闭角度检测
    if '--no-angle' in args:
        use_angle_cls = False

    # OCR 文本清理
    clean_text = '--clean' in args

    # 文本格式化
    format_text = '--format' in args

    # 跳过商品明细
    skip_items = '--no-items' in args

    scan_bill(image, model, use_angle_cls, concurrent, clean_text, format_text, skip_items)


if __name__ == "__main__":
    main()
