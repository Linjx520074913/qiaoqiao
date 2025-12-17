"""
多订单解析器 - 处理订单列表页面
能够识别并分离多个订单，分别解析
"""

import re
import logging
from typing import List, Tuple, Optional
from dataclasses import dataclass

from ..models import Invoice, InvoiceParseResult
from ..llm import OllamaEngine
from .fast_parser import FastBillParser
from .bank_parser import BankStatementParser

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class OrderBlock:
    """单个订单块"""
    text: str           # 订单文本
    start_line: int     # 起始行号
    end_line: int       # 结束行号
    status: str         # 订单状态（已完成/已取消/进行中）


class MultiOrderParser:
    """
    多订单解析器
    专门处理包含多个订单的页面（如订单列表）
    """

    # 订单分隔标记
    ORDER_SEPARATORS = [
        r'再来一单',
        r'(已完成|已取消|进行中|待支付|待发货)',
        r'餐厅>',
        r'订单号[：:]\s*\w+',
    ]

    # 订单状态关键词
    STATUS_KEYWORDS = {
        '已完成': 'completed',
        '已取消': 'cancelled',
        '进行中': 'in_progress',
        '待支付': 'pending_payment',
        '待发货': 'pending_shipment',
        '待收货': 'pending_receipt',
    }

    def __init__(self, llm_engine: OllamaEngine, skip_items: bool = False):
        """
        初始化多订单解析器

        Args:
            llm_engine: LLM 推理引擎
            skip_items: 是否跳过商品明细（仅提取总金额等关键信息）
        """
        self.llm_engine = llm_engine
        self.skip_items = skip_items
        self.parser = FastBillParser(llm_engine, skip_items=skip_items)
        mode = " (summary mode)" if skip_items else ""
        logger.info(f"MultiOrderParser initialized{mode}")

    def is_order_list(self, text: str) -> Tuple[bool, float]:
        """
        检测是否是订单列表页面（包括银行流水列表）

        Args:
            text: OCR 文本

        Returns:
            (是否是订单列表, 置信度)
        """
        score = 0
        indicators = 0

        # 检查 "我的订单" 标题
        if '我的订单' in text or '订单列表' in text:
            score += 3
            indicators += 1

        # 检查多个 "再来一单"
        reorder_count = text.count('再来一单')
        if reorder_count >= 2:
            score += reorder_count * 2
            indicators += 1

        # 检查多个订单状态
        status_count = sum(text.count(status) for status in self.STATUS_KEYWORDS.keys())
        if status_count >= 2:
            score += status_count
            indicators += 1

        # 检查多个商家名称（餐厅>）
        restaurant_count = text.count('餐厅>')
        if restaurant_count >= 2:
            score += restaurant_count * 2
            indicators += 1

        # 检查多个 "共N件"
        items_count = len(re.findall(r'共\d+件', text))
        if items_count >= 2:
            score += items_count
            indicators += 1

        # === 新增：检测银行流水列表 ===
        # 检查多条银行短信
        bank_sms_count = text.count('【中国银行】') + text.count('【建设银行】') + \
                        text.count('【工商银行】') + text.count('【农业银行】')
        if bank_sms_count >= 2:
            score += bank_sms_count * 2
            indicators += 1

        # 检查多个交易记录
        transaction_patterns = [
            r'于\d{1,2}月\d{1,2}日.*?(支取|收入).*?人民币.*?元',
            r'交易后余额[\d.]+',
        ]
        transaction_count = sum(len(re.findall(pattern, text)) for pattern in transaction_patterns)
        if transaction_count >= 4:  # 至少2条交易（每条有2个匹配）
            score += transaction_count
            indicators += 1

        # 计算置信度
        if indicators == 0:
            return False, 0.0

        # 如果有多个强指标，认为是列表
        is_list = indicators >= 2 or reorder_count >= 3 or bank_sms_count >= 2
        confidence = min(score / 10.0, 1.0)

        return is_list, confidence

    def split_orders(self, text: str) -> List[OrderBlock]:
        """
        分割订单列表为独立订单（包括银行流水）

        Args:
            text: OCR 文本

        Returns:
            订单块列表
        """
        # 先检测是否是银行流水
        if self._is_bank_statement_list(text):
            return self._split_bank_statements(text)

        # 否则按订单列表处理
        lines = text.split('\n')
        orders = []
        current_order = []
        current_start = 0
        current_status = 'unknown'
        in_order_section = False  # 是否进入订单区域

        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue

            # 检测是否进入订单区域（第一个商家名称出现）
            if not in_order_section and '餐厅>' in line:
                in_order_section = True
                current_start = i

            # 如果还未进入订单区域，跳过（过滤页面头部）
            if not in_order_section:
                continue

            # 检查是否是订单状态
            for status_keyword, status_code in self.STATUS_KEYWORDS.items():
                if status_keyword in line:
                    current_status = status_keyword
                    break

            # 检查是否是订单分隔符
            is_separator = False
            if '再来一单' in line:
                is_separator = True
            elif i > current_start and '餐厅>' in line and current_order:
                is_separator = True

            if is_separator and current_order:
                # 验证是否是有效订单
                order_text = '\n'.join(current_order)
                if self._is_valid_order(order_text):
                    orders.append(OrderBlock(
                        text=order_text,
                        start_line=current_start,
                        end_line=i,
                        status=current_status
                    ))
                current_order = []
                current_start = i + 1
                current_status = 'unknown'
            else:
                current_order.append(line)

        # 保存最后一个订单
        if current_order:
            order_text = '\n'.join(current_order)
            if self._is_valid_order(order_text):
                orders.append(OrderBlock(
                    text=order_text,
                    start_line=current_start,
                    end_line=len(lines),
                    status=current_status
                ))

        return orders

    def _is_bank_statement_list(self, text: str) -> bool:
        """检测是否是银行流水列表"""
        bank_keywords = ['【中国银行】', '【建设银行】', '【工商银行】', '【农业银行】']
        bank_count = sum(text.count(keyword) for keyword in bank_keywords)
        return bank_count >= 2

    def _split_bank_statements(self, text: str) -> List[OrderBlock]:
        """分离银行流水短信 - 使用正则表达式分割"""
        import re
        statements = []

        # 使用正则表达式分割，匹配"您的借记卡账户"作为分隔符
        # 这比依赖银行标记更可靠，因为银行标记可能被 OCR 分割
        pattern = r'您的借记卡账户'

        # 先去除多余空白和换行
        text = re.sub(r'\n+', '\n', text)

        # 按照"您的借记卡账户"分割
        parts = re.split(f'({pattern})', text)

        # 重新组合：每个"您的借记卡账户"和后面的内容组成一条记录
        transactions = []
        for i in range(1, len(parts), 2):  # 从1开始，步长为2
            if i < len(parts):
                transaction_text = parts[i] + (parts[i+1] if i+1 < len(parts) else '')
                transactions.append(transaction_text)

        # 转换为 OrderBlock
        for i, trans_text in enumerate(transactions):
            if self._is_valid_bank_statement(trans_text):
                statements.append(OrderBlock(
                    text=trans_text.strip(),
                    start_line=i,
                    end_line=i+1,
                    status='已完成'
                ))

        return statements

    def _is_valid_bank_statement(self, text: str) -> bool:
        """验证是否是有效的银行流水"""
        # 移除换行符以处理跨行的文本
        text_clean = text.replace('\n', '')

        # 必须包含金额和余额
        has_amount = bool(re.search(r'人民币[\d.]+元', text_clean))
        has_balance = '余额' in text_clean
        has_bank = any(bank in text_clean for bank in ['中国银行', '建设银行', '工商银行', '农业银行'])

        return has_amount and (has_balance or has_bank)

    def _is_valid_order(self, order_text: str) -> bool:
        """
        验证是否是有效订单

        Args:
            order_text: 订单文本

        Returns:
            是否有效
        """
        # 订单必须包含以下至少一项关键特征
        has_merchant = '餐厅>' in order_text or '店铺' in order_text
        has_amount = bool(re.search(r'[¥￥]\s*[\d.]+', order_text))
        has_items = '共' in order_text and '件' in order_text
        has_status = any(status in order_text for status in self.STATUS_KEYWORDS.keys())

        # 至少需要有商家名称或金额
        # 并且不能只是导航栏文本
        is_navigation = all(keyword in order_text for keyword in ['全部', '到店取餐', '麦乐送'])

        if is_navigation:
            return False

        return (has_merchant or has_amount) and (has_items or has_status or has_amount)

    def parse_order_list(self, text: str) -> Tuple[List[InvoiceParseResult], dict]:
        """
        解析订单列表

        Args:
            text: OCR 文本

        Returns:
            (订单解析结果列表, 统计信息)
        """
        # 分割订单
        order_blocks = self.split_orders(text)

        logger.info(f"Detected {len(order_blocks)} orders in list")

        # 检测是否是银行流水
        is_bank_statement = self._is_bank_statement_list(text)

        results = []
        stats = {
            'total_orders': len(order_blocks),
            'completed': 0,
            'cancelled': 0,
            'in_progress': 0,
            'other': 0,
        }

        for i, block in enumerate(order_blocks, 1):
            logger.info(f"Parsing order {i}/{len(order_blocks)} (status: {block.status})")

            # 根据类型选择解析器
            if is_bank_statement:
                bank_parser = BankStatementParser()
                result = bank_parser.parse(block.text)
            else:
                result = self.parser.parse(block.text)

            # 添加订单状态信息
            if result.success and result.invoice:
                if not result.invoice.remarks:
                    result.invoice.remarks = f"订单状态: {block.status}"
                else:
                    result.invoice.remarks += f" | 订单状态: {block.status}"

            results.append(result)

            # 统计
            if block.status == '已完成':
                stats['completed'] += 1
            elif block.status == '已取消':
                stats['cancelled'] += 1
            elif block.status in ['进行中', '待支付', '待发货', '待收货']:
                stats['in_progress'] += 1
            else:
                stats['other'] += 1

        return results, stats

    def parse(self, text: str) -> Tuple[bool, Optional[List[InvoiceParseResult]], Optional[dict]]:
        """
        智能解析：自动检测单个订单或订单列表

        Args:
            text: OCR 文本

        Returns:
            (是否是订单列表, 解析结果, 统计信息)
        """
        # 检测是否是订单列表
        is_list, confidence = self.is_order_list(text)

        if is_list:
            logger.info(f"Detected as order list (confidence: {confidence:.1%})")
            results, stats = self.parse_order_list(text)
            return True, results, stats
        else:
            logger.info("Detected as single order")
            return False, None, None
