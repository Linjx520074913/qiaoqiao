"""
Turbo 解析器 - 极致速度优化
通过极简提示词 + 后处理保证准确性
"""

import json
import logging
from typing import Optional, Union

from ..models import Invoice, InvoiceParseResult

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TurboBillParser:
    """Turbo 解析器 - 极致速度（支持 Ollama/vLLM）"""

    # 极简提示词（40 tokens，从 120 tokens 压缩）
    TURBO_PROMPT = """提取账单 JSON。
字段: seller_name, total_amount, items[name,quantity,amount]
金额为数字，未知为 null。

文本：
{text}

JSON:"""

    def __init__(self, llm_engine):
        """
        初始化 Turbo 解析器

        Args:
            llm_engine: LLM 引擎（OllamaEngine 或 vLLMEngine）
        """
        self.llm_engine = llm_engine
        engine_type = type(llm_engine).__name__
        logger.info(f"TurboBillParser initialized (ultra-fast mode, engine: {engine_type})")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        极速解析账单

        Args:
            ocr_text: OCR 文本

        Returns:
            解析结果
        """
        try:
            # 构建极简提示词
            prompt = self.TURBO_PROMPT.format(text=ocr_text[:400])  # 限制输入长度

            # LLM 推理 - 极简配置
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.0,
                max_tokens=300,  # 进一步减少（从 512 到 300）
            )

            # 添加原始文本
            json_output["raw_text"] = ocr_text

            # 清理和修复
            json_output = self._clean_and_fix(json_output)

            # 转换为 Invoice
            invoice = Invoice(**json_output)

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=0.85,
                parse_mode="turbo",
            )

        except Exception as e:
            logger.error(f"Turbo parsing error: {e}")
            return InvoiceParseResult(
                success=False,
                error_message=str(e),
            )

    def _clean_and_fix(self, data: dict) -> dict:
        """清理和修复数据（快速实现 + 保证准确性）"""
        import re

        def clean_number(value):
            if value is None or isinstance(value, (int, float)):
                return value
            if isinstance(value, str):
                value = re.sub(r'[￥¥$€×x份件个]', '', value).strip()
                try:
                    return float(value) if '.' in value else int(value)
                except:
                    return None
            return None

        # 清理金额
        for field in ['total_amount', 'subtotal']:
            if field in data and data[field]:
                data[field] = clean_number(data[field])

        # 清理商品
        if 'items' in data and isinstance(data['items'], list):
            cleaned_items = []
            for item in data['items']:
                if isinstance(item, dict):
                    # 清理字段
                    for field in ['quantity', 'amount']:
                        if field in item and item[field]:
                            item[field] = clean_number(item[field])

                    # 过滤无效商品
                    name = item.get('name', '')
                    if name and '份量' not in name and '口味' not in name:
                        cleaned_items.append(item)

            data['items'] = cleaned_items

        # 修复总金额（关键！保证准确性）
        raw_text = data.get('raw_text', '')
        patterns = [
            r'实付[：:\s]*[￥¥]?([\d.]+)',
            r'应付[：:\s]*[￥¥]?([\d.]+)',
            r'合计[^¥￥\d]*[¥￥]?([\d.]+)',
        ]

        for pattern in patterns:
            matches = re.findall(pattern, raw_text)
            if matches:
                data['total_amount'] = float(matches[-1])
                break

        return data
