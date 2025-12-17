#!/usr/bin/env python3
"""
快速账单扫描工具
用法: python3 scan_bill.py <图片路径>
支持单个订单和订单列表
"""

import sys
import os
import time
import logging
from pathlib import Path

# 设置日志级别为 WARNING，隐藏 INFO 日志
logging.basicConfig(level=logging.WARNING)

sys.path.insert(0, os.path.dirname(__file__))

from src.ocr import RapidOCREngine
from src.llm import OllamaEngine
from src.parser.smart_parser import SmartParser
from src.parser.multi_order_parser import MultiOrderParser


def scan_bill(image_path: str, model: str = "qwen2.5:3b"):
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
    ocr = RapidOCREngine(use_angle_cls=True, print_verbose=False)
    ocr_result = ocr.extract_text(image_path)
    times['ocr'] = time.time() - t

    if not ocr_result.success:
        print(f"✗ 失败: {ocr_result.error_message}")
        return
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
    multi_parser = MultiOrderParser(llm)
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
        results, stats = multi_parser.parse_order_list(ocr_result.text)
        times['parse'] = time.time() - t
        print(f"✓ ({times['parse']:.2f}s)")

        times['total'] = time.time() - total_start

        # 显示订单列表结果
        display_order_list_results(results, stats, times)

    else:
        # 单个订单处理
        print("[ 4/5 ] 检测账单类型...", end=" ", flush=True)
        t = time.time()
        parser = SmartParser(llm)
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
    if len(sys.argv) < 2:
        print("用法: python3 scan_bill.py <图片路径> [模型]")
        print("\n示例:")
        print("  python3 scan_bill.py bill.jpg")
        print("  python3 scan_bill.py invoice.png qwen2.5:7b")
        print("\n特性:")
        print("  ✓ 自动识别单个订单或订单列表")
        print("  ✓ 智能分离和解析多个订单")
        print("  ✓ 支持 20+ 个餐饮/电商平台")
        sys.exit(1)

    image = sys.argv[1]
    model = sys.argv[2] if len(sys.argv) > 2 else "qwen2.5:3b"

    scan_bill(image, model)


if __name__ == "__main__":
    main()
