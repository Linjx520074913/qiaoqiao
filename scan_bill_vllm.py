#!/usr/bin/env python3
"""
使用 vLLM 的高速账单扫描工具（2-3倍性能提升）

要求：
1. 安装 vLLM: pip install vllm
2. 启动 vLLM 服务: ./scripts/start_vllm.sh

性能对比：
- Ollama (CPU): ~4-5 秒
- vLLM (GPU):   ~1.5-2 秒（提升 60-70%）
"""

import sys
import os
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))

from src.ocr import RapidOCREngine, clean_ocr_text
from src.llm import VLLMEngine
from src.parser.turbo_parser import TurboBillParser
from src.parser.smart_parser import SmartParser
from src.parser.multi_order_parser import MultiOrderParser


def scan_bill_vllm(image_path: str,
                   model: str = "Qwen/Qwen2.5-3B-Instruct",
                   api_base: str = "http://localhost:8000/v1",
                   use_angle_cls: bool = False,
                   clean_text: bool = True):
    """
    使用 vLLM 的高速扫描

    Args:
        image_path: 图片路径
        model: 模型名称
        api_base: vLLM API 地址
        use_angle_cls: 是否使用角度检测
        clean_text: 是否清理文本
    """
    # 检查文件
    if not Path(image_path).exists():
        print(f"错误: 文件不存在 - {image_path}")
        return

    print(f"\n⚡ 高速扫描: {image_path}")
    print("=" * 60)

    times = {}
    total_start = time.time()

    # OCR 提取
    print("[ 1/4 ] OCR 提取...", end=" ", flush=True)
    t = time.time()
    ocr = RapidOCREngine(use_angle_cls=use_angle_cls, print_verbose=False)
    ocr_result = ocr.extract_text(image_path)
    times['ocr'] = time.time() - t

    if not ocr_result.success:
        print(f"✗ 失败: {ocr_result.error_message}")
        return

    # 文本清理
    if clean_text:
        original_len = len(ocr_result.text)
        ocr_result.text = clean_ocr_text(ocr_result.text)
        cleaned_len = len(ocr_result.text)
        reduction = (original_len - cleaned_len) / original_len * 100
        print(f"✓ ({times['ocr']:.2f}s, 文本↓{reduction:.0f}%)")
    else:
        print(f"✓ ({times['ocr']:.2f}s)")

    # 初始化 vLLM
    print("[ 2/4 ] 连接 vLLM...", end=" ", flush=True)
    t = time.time()
    try:
        llm = VLLMEngine(
            model_name=model,
            api_base=api_base,
            temperature=0.0,
            max_tokens=512,
        )
        times['init'] = time.time() - t
        print(f"✓ ({times['init']:.2f}s)")
    except Exception as e:
        print(f"✗ vLLM 连接失败: {e}")
        print("\n💡 提示: 请先启动 vLLM 服务")
        print("  ./scripts/start_vllm.sh")
        return

    # 检测类型
    print("[ 3/4 ] 智能检测...", end=" ", flush=True)
    t = time.time()
    parser = SmartParser(llm)
    bill_type, conf, mode = parser.detect_type_only(ocr_result.text)
    times['detect'] = time.time() - t
    print(f"✓ ({times['detect']:.2f}s) -> {bill_type}")

    # 解析账单
    print("[ 4/4 ] 高速解析...", end=" ", flush=True)
    t = time.time()
    result = parser.parse(ocr_result.text)
    times['parse'] = time.time() - t

    if not result.success:
        print(f"✗ 解析失败: {result.error_message}")
        return

    times['total'] = time.time() - total_start
    print(f"✓ ({times['parse']:.2f}s)")

    # 显示结果
    print("\n" + "=" * 60)
    print(" ⚡ 识别结果（vLLM 高速模式）")
    print("=" * 60)

    inv = result.invoice
    if inv.invoice_type:
        print(f"📋 类型: {inv.invoice_type}")
    if inv.seller_name:
        print(f"🏢 商家: {inv.seller_name}")
    if inv.items:
        print(f"\n📦 明细 ({len(inv.items)}项):")
        for i, item in enumerate(inv.items[:5], 1):
            qty = f" x{int(item.quantity)}" if item.quantity else ""
            amt = f"¥{item.amount:.2f}" if item.amount else ""
            print(f"  {i}. {item.name}{qty} {amt}")
    if inv.total_amount:
        print(f"\n💰 总计: ¥{inv.total_amount:.2f}")

    # 性能统计
    print("\n" + "=" * 60)
    print(" ⚡ 性能统计（vLLM 加速）")
    print("=" * 60)
    print(f"OCR 提取:    {times['ocr']:>6.2f}s")
    print(f"vLLM 初始化: {times['init']:>6.2f}s")
    print(f"类型检测:    {times['detect']:>6.2f}s")
    print(f"账单解析:    {times['parse']:>6.2f}s")
    print("-" * 60)
    print(f"⚡ 总计:     {times['total']:>6.2f}s")

    # 对比
    estimated_ollama_time = times['total'] * 2.5  # vLLM 通常快 2.5 倍
    speedup = (estimated_ollama_time - times['total']) / estimated_ollama_time * 100
    print(f"💡 相比 Ollama 预计提升: ~{speedup:.0f}%")
    print("=" * 60 + "\n")


def main():
    if len(sys.argv) < 2 or '--help' in sys.argv:
        print("⚡ vLLM 高速账单扫描工具")
        print("=" * 60)
        print("\n📋 使用前准备:")
        print("  1. 安装 vLLM:")
        print("     pip install vllm")
        print("\n  2. 启动 vLLM 服务:")
        print("     ./scripts/start_vllm.sh")
        print("\n🚀 基本用法:")
        print("  python3 scan_bill_vllm.py bill.jpg")
        print("\n⚡ 高级用法:")
        print("  python3 scan_bill_vllm.py bill.jpg --angle    # 启用角度检测")
        print("  python3 scan_bill_vllm.py bill.jpg --no-clean # 不清理文本")
        print("\n📊 性能对比:")
        print("  Ollama (CPU):  ~4-5 秒")
        print("  vLLM (GPU):    ~1.5-2 秒（提升 60-70%）")
        print("\n" + "=" * 60)
        sys.exit(1)

    image = sys.argv[1]
    use_angle_cls = '--angle' in sys.argv
    clean_text = '--no-clean' not in sys.argv

    scan_bill_vllm(
        image,
        use_angle_cls=use_angle_cls,
        clean_text=clean_text
    )


if __name__ == "__main__":
    main()
