"""
账单解析器核心逻辑
"""

import json
import logging
from typing import Optional
from jsonschema import validate, ValidationError

from ..models import Invoice, InvoiceParseResult
from ..llm import VLLMEngine
from ..prompts import PromptTemplate

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BillParser:
    """智能账单解析器"""

    # JSON Schema 用于验证输出
    INVOICE_SCHEMA = {
        "type": "object",
        "properties": {
            "invoice_type": {"type": ["string", "null"]},
            "invoice_number": {"type": ["string", "null"]},
            "invoice_date": {"type": ["string", "null"]},
            "seller_name": {"type": ["string", "null"]},
            "seller_tax_id": {"type": ["string", "null"]},
            "seller_address": {"type": ["string", "null"]},
            "seller_phone": {"type": ["string", "null"]},
            "seller_bank": {"type": ["string", "null"]},
            "seller_account": {"type": ["string", "null"]},
            "buyer_name": {"type": ["string", "null"]},
            "buyer_tax_id": {"type": ["string", "null"]},
            "buyer_address": {"type": ["string", "null"]},
            "buyer_phone": {"type": ["string", "null"]},
            "subtotal": {"type": ["number", "null"]},
            "tax_amount": {"type": ["number", "null"]},
            "total_amount": {"type": ["number", "null"]},
            "items": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "quantity": {"type": ["number", "null"]},
                        "unit_price": {"type": ["number", "null"]},
                        "amount": {"type": ["number", "null"]},
                        "description": {"type": ["string", "null"]},
                    },
                    "required": ["name"],
                },
            },
            "payment_method": {"type": ["string", "null"]},
            "remarks": {"type": ["string", "null"]},
        },
    }

    def __init__(
        self,
        llm_engine: VLLMEngine,
        use_few_shot: bool = True,
        validate_output: bool = True,
    ):
        """
        初始化账单解析器

        Args:
            llm_engine: LLM 推理引擎
            use_few_shot: 是否使用 few-shot 示例
            validate_output: 是否验证 JSON 输出
        """
        self.llm_engine = llm_engine
        self.use_few_shot = use_few_shot
        self.validate_output = validate_output

        logger.info("BillParser initialized")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        解析账单文本

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            账单解析结果
        """
        try:
            # 构建提示词
            if self.use_few_shot:
                prompt = PromptTemplate.build_prompt(ocr_text)
            else:
                prompt = PromptTemplate.build_simple_prompt(ocr_text)

            logger.info(f"Parsing invoice from text (length: {len(ocr_text)})")

            # 调用 LLM 生成 JSON
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.1,  # 使用较低的温度以获得更确定的输出
            )

            # 验证 JSON 格式
            if self.validate_output:
                try:
                    validate(instance=json_output, schema=self.INVOICE_SCHEMA)
                    logger.info("JSON validation passed")
                except ValidationError as e:
                    logger.warning(f"JSON validation failed: {e}")
                    # 验证失败但继续处理

            # 添加原始文本
            json_output["raw_text"] = ocr_text

            # 转换为 Invoice 对象
            invoice = Invoice(**json_output)

            # 计算置信度（简单实现：基于提取到的字段数量）
            confidence = self._calculate_confidence(invoice)

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=confidence,
            )

        except Exception as e:
            logger.error(f"Error parsing invoice: {e}")
            return InvoiceParseResult(
                success=False,
                error_message=str(e),
            )

    def parse_batch(self, ocr_texts: list[str]) -> list[InvoiceParseResult]:
        """
        批量解析账单

        Args:
            ocr_texts: OCR 文本列表

        Returns:
            解析结果列表
        """
        results = []
        for i, text in enumerate(ocr_texts):
            logger.info(f"Parsing invoice {i + 1}/{len(ocr_texts)}")
            result = self.parse(text)
            results.append(result)
        return results

    def _calculate_confidence(self, invoice: Invoice) -> float:
        """
        计算置信度

        Args:
            invoice: 账单对象

        Returns:
            置信度 0-1
        """
        # 重要字段
        important_fields = [
            "invoice_type",
            "invoice_number",
            "invoice_date",
            "total_amount",
        ]

        # 次要字段
        secondary_fields = [
            "seller_name",
            "buyer_name",
            "subtotal",
            "tax_amount",
        ]

        # 计算填充的字段数
        important_count = sum(
            1
            for field in important_fields
            if getattr(invoice, field, None) is not None
        )
        secondary_count = sum(
            1
            for field in secondary_fields
            if getattr(invoice, field, None) is not None
        )
        items_count = 1 if len(invoice.items) > 0 else 0

        # 加权计算置信度
        confidence = (
            important_count * 0.15
            + secondary_count * 0.05
            + items_count * 0.2
        )

        return min(confidence, 1.0)

    def to_json(self, result: InvoiceParseResult, indent: int = 2) -> str:
        """
        将解析结果转换为 JSON 字符串

        Args:
            result: 解析结果
            indent: 缩进空格数

        Returns:
            JSON 字符串
        """
        return json.dumps(result.to_dict(), ensure_ascii=False, indent=indent)
