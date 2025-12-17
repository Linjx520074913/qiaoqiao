"""
智能解析器 - 自动识别文本类型并选择最佳解析模式
"""

import re
import logging
from typing import Optional, Tuple
from enum import Enum

from ..models import InvoiceParseResult
from ..llm import OllamaEngine
from .bill_parser import BillParser
from .fast_parser import FastBillParser
from .hybrid_parser import HybridParser

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BillType(Enum):
    """账单类型枚举"""
    BANK_STATEMENT = "bank_statement"      # 银行流水
    ECOMMERCE_ORDER = "ecommerce_order"    # 电商订单
    FOOD_DELIVERY = "food_delivery"        # 外卖订单
    VAT_INVOICE = "vat_invoice"            # 增值税发票
    RECEIPT = "receipt"                    # 收据
    UNKNOWN = "unknown"                    # 未知


class ParserMode(Enum):
    """解析模式枚举"""
    STANDARD = "standard"    # 标准模式
    FAST = "fast"           # 快速模式
    HYBRID = "hybrid"       # 混合模式


class SmartParser:
    """智能解析器 - 自动选择最佳模式"""

    # 账单类型识别规则
    DETECTION_RULES = {
        BillType.BANK_STATEMENT: {
            'keywords': ['银行', '借记卡', '账户', '支取', '收入', '交易后余额', '转账'],
            'patterns': [
                r'于\d{1,2}月\d{1,2}日.*?(支取|收入)人民币',
                r'交易后余额[\d.]+',
                r'账户\d{4,8}',
            ],
            'weight': 3,  # 权重
        },
        BillType.FOOD_DELIVERY: {
            'keywords': [
                # 外卖平台
                '美团', '饿了么', '外卖', '配送', '骑手', '送达', '麦乐送',
                # 餐饮品牌
                '麦当劳', '肯德基', '星巴克', '必胜客', '汉堡王', '德克士',
                '瑞幸咖啡', '喜茶', '奈雪', '海底捞', '西贝',
                # 订单特征
                '到店取餐', '堂食', '自取', '外送', '打包',
                '再来一单', '口味', '备注', '餐具',
            ],
            'patterns': [
                r'预计\d{2}:\d{2}.*?送达',
                r'配送费',
                r'到店取餐',
                r'外送|外卖',
                r'再来一单',
                r'餐厅>',
                r'(已完成|已取消|进行中).*?共\d+件',
            ],
            'weight': 2,
        },
        BillType.ECOMMERCE_ORDER: {
            'keywords': [
                # 电商平台
                '淘宝', '京东', '拼多多', '天猫', '唯品会', '苏宁',
                # 通用关键词
                '订单号', '收货人', '快递', '物流', '订单详情',
                '下单时间', '店铺', '发货', '签收',
                '我的订单', '待收货', '待评价',
            ],
            'patterns': [
                r'订单号[：:]\s*[A-Z0-9]{10,}',
                r'实付[金额款]?[：:]\s*[¥￥]?[\d.]+',
                r'我的订单',
                r'订单详情',
                r'收货地址',
            ],
            'weight': 2,
        },
        BillType.VAT_INVOICE: {
            'keywords': ['增值税', '专用发票', '普通发票', '发票代码', '纳税人识别号', '开票日期'],
            'patterns': [
                r'发票[代号码]{1,2}[：:]\s*\d{8,}',
                r'纳税人识别号',
                r'价税合计',
            ],
            'weight': 3,
        },
        BillType.RECEIPT: {
            'keywords': ['收据', '收款', '经手人', '付款人'],
            'patterns': [
                r'收据',
                r'[收付]款[人单位]',
            ],
            'weight': 1,
        },
    }

    # 类型到解析模式的映射
    TYPE_TO_MODE = {
        BillType.BANK_STATEMENT: ParserMode.HYBRID,      # 银行流水用混合模式
        BillType.FOOD_DELIVERY: ParserMode.FAST,         # 外卖用快速模式
        BillType.ECOMMERCE_ORDER: ParserMode.FAST,       # 电商订单用快速模式
        BillType.VAT_INVOICE: ParserMode.STANDARD,       # 发票用标准模式
        BillType.RECEIPT: ParserMode.FAST,               # 收据用快速模式
        BillType.UNKNOWN: ParserMode.FAST,               # 未知用快速模式
    }

    def __init__(self, llm_engine: OllamaEngine):
        """
        初始化智能解析器

        Args:
            llm_engine: LLM 推理引擎
        """
        self.llm_engine = llm_engine

        # 预初始化三种解析器
        self.standard_parser = BillParser(llm_engine, use_few_shot=True)
        self.fast_parser = FastBillParser(llm_engine)
        self.hybrid_parser = HybridParser(llm_engine)

        logger.info("SmartParser initialized (auto mode selection)")

    def parse(self, ocr_text: str, force_mode: Optional[ParserMode] = None) -> InvoiceParseResult:
        """
        智能解析

        Args:
            ocr_text: OCR 识别的文本
            force_mode: 强制使用指定模式（可选）

        Returns:
            账单解析结果
        """
        # 1. 检测账单类型
        bill_type, confidence = self._detect_bill_type(ocr_text)
        logger.info(f"Detected bill type: {bill_type.value} (confidence: {confidence:.2%})")

        # 2. 选择解析模式
        if force_mode:
            mode = force_mode
            logger.info(f"Using forced mode: {mode.value}")
        else:
            mode = self.TYPE_TO_MODE.get(bill_type, ParserMode.FAST)
            logger.info(f"Auto-selected mode: {mode.value}")

        # 3. 使用对应的解析器
        parser = self._get_parser(mode)
        result = parser.parse(ocr_text)

        # 4. 在结果中附加检测信息
        if result.success and result.invoice:
            if not result.invoice.invoice_type:
                result.invoice.invoice_type = bill_type.value.replace('_', ' ').title()

        return result

    def _detect_bill_type(self, text: str) -> Tuple[BillType, float]:
        """
        检测账单类型

        Args:
            text: 文本内容

        Returns:
            (账单类型, 置信度)
        """
        scores = {}

        for bill_type, rules in self.DETECTION_RULES.items():
            score = 0

            # 检查关键词
            keywords = rules['keywords']
            keyword_matches = sum(1 for kw in keywords if kw in text)
            score += keyword_matches * 1.0

            # 检查正则模式
            patterns = rules['patterns']
            pattern_matches = sum(1 for pattern in patterns if re.search(pattern, text))
            score += pattern_matches * 2.0

            # 应用权重
            score *= rules['weight']

            scores[bill_type] = score

        # 找出得分最高的类型
        if not scores or max(scores.values()) == 0:
            return BillType.UNKNOWN, 0.0

        best_type = max(scores, key=scores.get)
        best_score = scores[best_type]

        # 计算置信度（归一化）
        total_score = sum(scores.values())
        confidence = best_score / total_score if total_score > 0 else 0

        return best_type, confidence

    def _get_parser(self, mode: ParserMode):
        """获取对应模式的解析器"""
        if mode == ParserMode.STANDARD:
            return self.standard_parser
        elif mode == ParserMode.FAST:
            return self.fast_parser
        elif mode == ParserMode.HYBRID:
            return self.hybrid_parser
        else:
            return self.fast_parser

    def detect_type_only(self, text: str) -> Tuple[str, float, str]:
        """
        仅检测类型（不解析）

        Args:
            text: 文本内容

        Returns:
            (类型名称, 置信度, 推荐模式)
        """
        bill_type, confidence = self._detect_bill_type(text)
        mode = self.TYPE_TO_MODE.get(bill_type, ParserMode.FAST)

        type_name = bill_type.value.replace('_', ' ').title()
        mode_name = mode.value

        return type_name, confidence, mode_name

    def to_json(self, result: InvoiceParseResult, indent: int = 2) -> str:
        """转换为JSON字符串"""
        import json
        return json.dumps(result.to_dict(), ensure_ascii=False, indent=indent)
