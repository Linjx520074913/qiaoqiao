"""
快速账单解析器 - 性能优化版本
"""

import json
import logging
from typing import Optional

from ..models import Invoice, InvoiceParseResult
from ..llm import OllamaEngine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class FastBillParser:
    """快速账单解析器 - 牺牲少量准确率换取速度"""

    # 精简的提示词（无 few-shot 示例）
    FAST_PROMPT_TEMPLATE = """你是账单信息提取助手。从文本中提取账单信息并输出 JSON。

要求：
1. 提取字段：invoice_type, invoice_number, invoice_date, seller_name, buyer_name, buyer_phone, buyer_address, total_amount, items
2. 对于 items，提取 name, quantity, amount
3. 金额必须是纯数字（如 16.2），不要货币符号
4. 数量必须是纯数字（如 1），不要 "x" 前缀
5. 无法确定的字段设为 null
6. 必须输出有效的 JSON，不要其他文字

输入文本：
{text}

输出 JSON："""

    def __init__(
        self,
        llm_engine: OllamaEngine,
        validate_output: bool = False,  # 快速模式默认不验证
    ):
        """
        初始化快速解析器

        Args:
            llm_engine: LLM 推理引擎
            validate_output: 是否验证输出（关闭以提升速度）
        """
        self.llm_engine = llm_engine
        self.validate_output = validate_output
        logger.info("FastBillParser initialized (optimized for speed)")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        快速解析账单

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            账单解析结果
        """
        try:
            # 构建精简提示词
            prompt = self.FAST_PROMPT_TEMPLATE.format(text=ocr_text)

            logger.info(f"Fast parsing (text length: {len(ocr_text)})")

            # 调用 LLM - 使用更低温度和更少 token
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.0,  # 最低温度，更快
                max_tokens=1024,  # 减少输出长度
            )

            # 添加原始文本
            json_output["raw_text"] = ocr_text

            # 转换为 Invoice 对象
            invoice = Invoice(**json_output)

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=0.8,  # 快速模式固定置信度
            )

        except Exception as e:
            logger.error(f"Fast parsing error: {e}")
            return InvoiceParseResult(
                success=False,
                error_message=str(e),
            )

    def parse_batch(self, ocr_texts: list[str]) -> list[InvoiceParseResult]:
        """批量快速解析"""
        results = []
        for i, text in enumerate(ocr_texts):
            logger.info(f"Fast parsing {i + 1}/{len(ocr_texts)}")
            result = self.parse(text)
            results.append(result)
        return results

    def to_json(self, result: InvoiceParseResult, indent: int = 2) -> str:
        """转换为 JSON 字符串"""
        return json.dumps(result.to_dict(), ensure_ascii=False, indent=indent)
