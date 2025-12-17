#!/usr/bin/env python3
"""
KAPI 客户端示例
演示如何调用 API 接口识别账单
"""

import requests
import json


def scan_bill(image_path: str, fast_mode: bool = True):
    """
    调用 KAPI API 识别账单

    Args:
        image_path: 图片路径
        fast_mode: 是否使用快速模式
    """

    # API 地址
    url = "http://localhost:8000/api/scan"

    # 参数
    params = {
        "fast_mode": fast_mode,
    }

    # 上传文件
    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(url, files=files, params=params)

    # 解析响应
    if response.status_code == 200:
        result = response.json()
        print("✅ 识别成功")
        print(f"📊 类型: {result['data']['type']}")

        if result['data']['type'] == 'order_list':
            # 订单列表
            stats = result['data']['statistics']
            print(f"📋 订单数: {stats['total_orders']}")
            print(f"✓ 已完成: {stats['completed']}")
            print(f"💰 总金额: ¥{result['data']['total_amount']}")

            print(f"\n订单详情:")
            for i, invoice in enumerate(result['data']['invoices'][:3], 1):
                print(f"  {i}. {invoice['seller_name']} - ¥{invoice['total_amount']}")

        else:
            # 单个订单
            invoice = result['data']['invoice']
            print(f"🏢 商家: {invoice['seller_name']}")
            print(f"💰 金额: ¥{invoice['total_amount']}")
            print(f"📦 商品: {len(invoice['items'])} 件")

        # 性能统计
        perf = result['performance']
        print(f"\n⏱️ 性能:")
        print(f"  总耗时: {perf['total_time']}s")
        print(f"  OCR: {perf['ocr_time']}s")
        print(f"  解析: {perf['parse_time']}s")

        return result

    else:
        print(f"❌ 识别失败: {response.status_code}")
        print(response.text)
        return None


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("用法: python3 client_example.py <图片路径>")
        print("\n示例:")
        print("  python3 client_example.py bill.jpg")
        sys.exit(1)

    image_path = sys.argv[1]
    result = scan_bill(image_path, fast_mode=True)

    # 保存结果
    if result:
        with open("result.json", "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"\n💾 结果已保存到 result.json")
