"""
银行流水解析器 - 直接提取结构化数据
"""

import re
import logging
from typing import Optional
from datetime import datetime

from ..models import Invoice, InvoiceItem, InvoiceParseResult

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BankStatementParser:
    """银行流水解析器 - 使用正则表达式直接提取"""

    BANK_PATTERNS = {
        '中国银行': r'【中国银行】',
        '建设银行': r'【建设银行】',
        '工商银行': r'【工商银行】',
        '农业银行': r'【农业银行】',
    }

    def parse(self, text: str) -> InvoiceParseResult:
        """
        解析银行流水短信

        Args:
            text: OCR 文本

        Returns:
            解析结果
        """
        try:
            # 移除换行符以处理跨行的文本
            text_clean = text.replace('\n', '')

            # 检测银行
            bank_name = self._detect_bank(text_clean)

            # 提取账户号
            account_match = re.search(r'账户(\d+)', text_clean)
            account_number = account_match.group(1) if account_match else None

            # 提取日期
            date_match = re.search(r'(\d+)月(\d+)日', text_clean)
            if date_match:
                month = date_match.group(1)
                day = date_match.group(2)
                # 假设是当前年份
                year = datetime.now().year
                invoice_date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"
            else:
                invoice_date = None

            # 提取交易类型和金额
            transaction_type = None
            amount = None

            # 支取交易
            withdraw_match = re.search(r'支取.*?人民币([\d.]+)元', text_clean)
            if withdraw_match:
                transaction_type = "支出"
                amount = float(withdraw_match.group(1))

            # 收入交易
            income_match = re.search(r'收入.*?人民币([\d.]+)元', text_clean)
            if income_match:
                transaction_type = "收入"
                amount = float(income_match.group(1))

            # 网上支付支取
            if not amount:
                payment_match = re.search(r'网上支付支取.*?人民币([\d.]+)元', text_clean)
                if payment_match:
                    transaction_type = "网上支付"
                    amount = float(payment_match.group(1))

            # 提取余额
            balance_match = re.search(r'余额([\d.]+)', text_clean)
            balance = float(balance_match.group(1)) if balance_match else None

            # 构建 Invoice 对象
            invoice = Invoice(
                invoice_type="Bank Statement",
                invoice_number=f"{bank_name}-{account_number}" if account_number else None,
                invoice_date=invoice_date,
                seller_name=bank_name,
                buyer_name=f"账户 {account_number}" if account_number else None,
                total_amount=amount,
                items=[
                    InvoiceItem(
                        name=f"{transaction_type}",
                        quantity=1,
                        amount=amount
                    )
                ] if transaction_type and amount else [],
                remarks=f"余额: ¥{balance:.2f}" if balance else None,
                raw_text=text
            )

            return InvoiceParseResult(
                success=True,
                invoice=invoice,
                confidence=0.95,  # 正则匹配，高置信度
                parse_mode="bank_statement",
                error_message=None
            )

        except Exception as e:
            logger.error(f"Bank statement parsing error: {e}")
            return InvoiceParseResult(
                success=False,
                invoice=None,
                confidence=0.0,
                parse_mode="bank_statement",
                error_message=str(e)
            )

    def _detect_bank(self, text: str) -> str:
        """检测银行名称"""
        for bank_name, pattern in self.BANK_PATTERNS.items():
            if re.search(pattern, text):
                return bank_name
        return "未知银行"
