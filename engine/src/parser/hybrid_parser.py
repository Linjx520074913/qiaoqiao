"""
混合解析器 - 规则过滤 + LLM
先用正则表达式提取结构化字段，再用LLM补充理解
"""

import re
import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

from ..models import Invoice, InvoiceItem, InvoiceParseResult
from ..llm import OllamaEngine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class HybridParser:
    """混合解析器 - 规则 + LLM"""

    # 规则模式定义
    PATTERNS = {
        # 金额模式：¥123.45 或 123.45元 或 人民币123.45元
        'amount': r'(?:¥|人民币)?(\d+\.?\d*)[元]?',

        # 日期模式：12月09日 或 2024-01-15 或 2024年01月15日
        'date': r'(\d{1,2})月(\d{1,2})日|(\d{4})-(\d{2})-(\d{2})|(\d{4})年(\d{2})月(\d{2})日',

        # 电话号码：11位手机号
        'phone': r'1[3-9]\d{9}',

        # 银行账户：4-8位数字
        'account': r'账户[：:]*(\d{4,8})',

        # 银行名称：【XX银行】
        'bank': r'【(.*?银行)】',

        # 中国银行交易记录
        'bank_transaction': r'于(\d{1,2})月(\d{1,2})日(.*?)(支取|收入)人民币([\d.]+)元，交易后余额([\d.]+)',

        # 淘宝/京东订单号
        'order_number': r'(?:订单号|订单编号)[：:]\s*([A-Z0-9]+)',

        # 发票号
        'invoice_number': r'(?:发票号码?|发票代码)[：:]\s*(\d+)',
    }

    def __init__(
        self,
        llm_engine: OllamaEngine,
        use_rules_first: bool = True,
    ):
        """
        初始化混合解析器

        Args:
            llm_engine: LLM 推理引擎
            use_rules_first: 是否优先使用规则提取
        """
        self.llm_engine = llm_engine
        self.use_rules_first = use_rules_first
        logger.info("HybridParser initialized (Rules + LLM)")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        混合解析

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            账单解析结果
        """
        try:
            logger.info(f"Hybrid parsing (text length: {len(ocr_text)})")

            # 第一步：使用规则提取
            rules_data = self._extract_by_rules(ocr_text)
            logger.info(f"Rules extracted: {len(rules_data)} fields")

            # 第二步：使用LLM补充
            llm_data = self._extract_by_llm(ocr_text, rules_data)

            # 第三步：合并结果（规则优先）
            final_data = self._merge_data(rules_data, llm_data)

            # 添加原始文本
            final_data["raw_text"] = ocr_text

            # 转换为 Invoice 对象
            invoice = Invoice(**final_data)

            # 计算置信度
            confidence = self._calculate_confidence(invoice, rules_data)

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=confidence,
            )

        except Exception as e:
            logger.error(f"Hybrid parsing error: {e}")
            return InvoiceParseResult(
                success=False,
                error_message=str(e),
            )

    def _extract_by_rules(self, text: str) -> Dict[str, Any]:
        """使用规则提取结构化信息"""
        data = {}

        # 提取银行名称
        bank_match = re.search(self.PATTERNS['bank'], text)
        if bank_match:
            data['seller_name'] = bank_match.group(1)

        # 提取账户号
        account_match = re.search(self.PATTERNS['account'], text)
        if account_match:
            data['invoice_number'] = account_match.group(1)

        # 提取订单号
        order_match = re.search(self.PATTERNS['order_number'], text)
        if order_match:
            data['invoice_number'] = order_match.group(1)

        # 提取发票号
        invoice_match = re.search(self.PATTERNS['invoice_number'], text)
        if invoice_match:
            data['invoice_number'] = invoice_match.group(1)

        # 提取电话号码
        phone_match = re.search(self.PATTERNS['phone'], text)
        if phone_match:
            data['buyer_phone'] = phone_match.group(0)

        # 特殊处理：中国银行交易记录
        bank_transactions = re.findall(self.PATTERNS['bank_transaction'], text)
        if bank_transactions:
            data['invoice_type'] = '银行流水'
            items = []
            last_balance = None

            for match in bank_transactions:
                month, day, desc, trans_type, amount, balance = match

                # 构建交易项
                item = {
                    'name': f"{month}月{day}日 {trans_type}",
                    'amount': float(amount) if trans_type == '收入' else -float(amount),
                    'description': desc.strip(),
                }
                items.append(item)
                last_balance = float(balance)

            data['items'] = items
            if last_balance is not None:
                data['total_amount'] = last_balance

        # 提取所有金额（如果没有明细）
        if 'items' not in data:
            amounts = re.findall(self.PATTERNS['amount'], text)
            if amounts:
                # 最后一个通常是总金额
                try:
                    data['total_amount'] = float(amounts[-1])
                except:
                    pass

        return data

    def _extract_by_llm(self, text: str, rules_data: Dict[str, Any]) -> Dict[str, Any]:
        """使用LLM补充提取"""

        # 构建精简的提示词，告诉LLM哪些字段已经提取
        extracted_fields = list(rules_data.keys())

        prompt = f"""从文本中提取账单信息并输出JSON。

已通过规则提取的字段：{', '.join(extracted_fields)}

请补充提取以下字段（如果文本中有）：
- invoice_type（账单类型）
- invoice_date（日期）
- buyer_name（购买方/收货人）
- buyer_address（地址）
- items（商品明细，如果规则未提取）
- remarks（备注）

要求：
1. 金额必须是纯数字
2. 日期格式：YYYY-MM-DD
3. 无法确定的字段设为null
4. 输出有效的JSON

输入文本：
{text}

输出JSON："""

        try:
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.0,
                max_tokens=1024,
            )
            return json_output
        except Exception as e:
            logger.warning(f"LLM extraction failed: {e}")
            return {}

    def _merge_data(self, rules_data: Dict[str, Any], llm_data: Dict[str, Any]) -> Dict[str, Any]:
        """合并规则和LLM的结果（规则优先）"""
        merged = {}

        # 规则提取的数据优先
        merged.update(llm_data)
        merged.update(rules_data)

        # 特殊处理：如果规则提取了items，不使用LLM的
        if 'items' in rules_data and rules_data['items']:
            merged['items'] = rules_data['items']

        return merged

    def _calculate_confidence(self, invoice: Invoice, rules_data: Dict[str, Any]) -> float:
        """计算置信度（规则提取的字段置信度更高）"""
        total_score = 0
        max_score = 0

        # 重要字段
        important_fields = {
            'invoice_type': (0.15, 'invoice_type' in rules_data),
            'invoice_number': (0.15, 'invoice_number' in rules_data),
            'total_amount': (0.2, 'total_amount' in rules_data),
            'seller_name': (0.1, 'seller_name' in rules_data),
        }

        for field, (weight, from_rules) in important_fields.items():
            max_score += weight
            value = getattr(invoice, field, None)
            if value is not None:
                # 规则提取的给更高分
                score = weight * (1.0 if from_rules else 0.8)
                total_score += score

        # 明细项目
        if invoice.items:
            max_score += 0.2
            total_score += 0.2

        # 次要字段
        secondary_fields = ['buyer_name', 'buyer_phone', 'invoice_date']
        for field in secondary_fields:
            max_score += 0.05
            if getattr(invoice, field, None) is not None:
                total_score += 0.05

        confidence = total_score / max_score if max_score > 0 else 0
        return min(confidence, 1.0)

    def to_json(self, result: InvoiceParseResult, indent: int = 2) -> str:
        """转换为JSON字符串"""
        return json.dumps(result.to_dict(), ensure_ascii=False, indent=indent)
