"""
账单解析器测试
"""

import os
import sys
import json

# 添加项目根目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from src.llm import VLLMEngine
from src.parser import BillParser


def test_with_sample_bill(sample_file: str):
    """使用示例账单测试"""

    print(f"\n{'=' * 80}")
    print(f"测试文件: {sample_file}")
    print(f"{'=' * 80}\n")

    # 读取示例文本
    sample_path = os.path.join(
        os.path.dirname(__file__), "sample_bills", sample_file
    )

    with open(sample_path, "r", encoding="utf-8") as f:
        ocr_text = f.read()

    print("OCR 输入文本:")
    print("-" * 80)
    print(ocr_text)
    print("-" * 80)

    # 初始化 vLLM 引擎
    print("\n初始化 vLLM 引擎...")
    llm_engine = VLLMEngine(
        model_name="mistralai/Mistral-7B-Instruct-v0.2",
        api_base="http://localhost:8000/v1",
        api_key="EMPTY",
    )

    # 测试连接
    print("测试 vLLM 服务连接...")
    if not llm_engine.test_connection():
        print("❌ 无法连接到 vLLM 服务，请确保服务已启动")
        print("\n启动 vLLM 服务的命令:")
        print(
            "python -m vllm.entrypoints.openai.api_server "
            "--model mistralai/Mistral-7B-Instruct-v0.2 "
            "--host 0.0.0.0 --port 8000"
        )
        return

    print("✓ 连接成功\n")

    # 初始化解析器
    parser = BillParser(llm_engine, use_few_shot=True)

    # 解析账单
    print("开始解析账单...\n")
    result = parser.parse(ocr_text)

    # 输出结果
    if result.success:
        print("✓ 解析成功!")
        print(f"置信度: {result.confidence:.2%}\n")

        print("解析结果（JSON）:")
        print("-" * 80)
        json_output = parser.to_json(result, indent=2)
        print(json_output)
        print("-" * 80)

        # 保存结果
        output_file = sample_file.replace(".txt", "_result.json")
        output_path = os.path.join(
            os.path.dirname(__file__), "sample_bills", output_file
        )
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(json_output)
        print(f"\n结果已保存到: {output_path}")

    else:
        print(f"❌ 解析失败: {result.error_message}")


def main():
    """主函数"""
    print("\n" + "=" * 80)
    print(" KAPI - 智能账单识别引擎 测试")
    print("=" * 80)

    # 测试所有示例文件
    sample_files = ["sample1.txt", "sample2.txt"]

    for sample_file in sample_files:
        try:
            test_with_sample_bill(sample_file)
        except Exception as e:
            print(f"\n❌ 测试失败: {e}")
            import traceback

            traceback.print_exc()

    print("\n" + "=" * 80)
    print(" 测试完成")
    print("=" * 80 + "\n")


if __name__ == "__main__":
    main()
