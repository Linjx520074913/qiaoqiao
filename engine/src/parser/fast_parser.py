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
6. total_amount 提取规则：
   - 查找"合计"、"实付"、"应付"、"总计"后面的最后一个金额（正数）
   - 负数金额是优惠，不要作为 total_amount
   - 优先级：合计 > 实付 > 应付 > 总计 > 商品总价
   - "到手"金额是优惠后价格，不要用作 total_amount
7. seller_name 提取完整的门店/商家名称
   - 提取完整名称（如：杨氏手撕烤鸭（丁头村店））
   - 不要仅提取分店名（如仅"丁头村店"不完整）
   - 不要提取：保险名称（如准时保、食安险）
   - 不要提取：平台名称（如美团、饿了么）
   - 不要提取：配送服务名称
8. items 提取规则：
   - 只提取实际商品名称和价格
   - 如果看到"份量"、"口味"、"备注"等关键词，这是商品说明，不是独立商品
   - 看到"数量×N"或"商品总价"时，前面的商品信息为一组
   - 商品 amount 是原价（商品总价），不是优惠后价格（到手价）
   - 一个商品只能有一个 amount，不要重复计算
9. invoice_type 提取订单类型（如：外卖、咖啡、发票等），不要提取金额标签
10. 必须输出有效的 JSON，不要其他文字

示例：
如果文本包含：
手撕烤鸭半只
到手￥7.87
份量，孜然辣椒
￥26.9
数量×1

应提取为：{{"items": [{{"name": "手撕烤鸭半只", "quantity": 1, "amount": 26.9}}]}}
（份量是说明，不是独立商品）

输入文本：
{text}

输出 JSON："""

    # 极简提示词（仅提取商家名和金额）
    SUMMARY_PROMPT_TEMPLATE = """从文本提取商家名和金额，输出 JSON。

字段：
- seller_name: 商家品牌名称
- total_amount: 总金额

seller_name 规则：
1. 查找"下单时间"后面的名称（最准确的商家名）
2. 提取品牌主体，不要门店编号
3. 错误示例：
   - ✗ "南山智谷店（No.10649）" - 这只是门店位置
   - ✓ "luckincoffee小程序" - 这才是商家
   - ✗ "杨氏手撕烤鸭（丁头村店）" - 如果末尾有更准确的品牌名，优先用品牌名
   - ✓ "杨氏手撕烤鸭" - 品牌主体

total_amount 规则：
提取"实付"或"合计"后的金额（纯数字）

示例：
文本中有：
"南山智谷店（No.10649）
...
下单时间：2025-12-0819:14luckincoffee小程序"

应提取：{{"seller_name": "luckincoffee小程序", "total_amount": 9.9}}

文本：
{text}

JSON："""

    def __init__(
        self,
        llm_engine: OllamaEngine,
        validate_output: bool = False,  # 快速模式默认不验证
        skip_items: bool = False,  # 是否跳过商品明细
    ):
        """
        初始化快速解析器

        Args:
            llm_engine: LLM 推理引擎
            validate_output: 是否验证输出（关闭以提升速度）
            skip_items: 是否跳过商品明细（仅提取总金额等关键信息）
        """
        self.llm_engine = llm_engine
        self.validate_output = validate_output
        self.skip_items = skip_items
        mode = "summary mode" if skip_items else "optimized for speed"
        logger.info(f"FastBillParser initialized ({mode})")

    def parse(self, ocr_text: str) -> InvoiceParseResult:
        """
        快速解析账单

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            账单解析结果
        """
        try:
            # 根据模式选择提示词和 max_tokens
            if self.skip_items:
                # 使用完整文本以确保能找到商家名（可能在末尾）
                prompt = self.SUMMARY_PROMPT_TEMPLATE.format(text=ocr_text)
                max_tokens = 100  # 给 LLM 足够空间理解提示词
                logger.info(f"Summary parsing (text length: {len(ocr_text)})")
            else:
                prompt = self.FAST_PROMPT_TEMPLATE.format(text=ocr_text)
                max_tokens = 512  # 标准输出
                logger.info(f"Fast parsing (text length: {len(ocr_text)})")

            # 调用 LLM - 使用更低温度和优化的 token 限制
            json_output = self.llm_engine.generate_json(
                prompt=prompt,
                temperature=0.0,  # 最低温度，更快
                max_tokens=max_tokens,
            )

            # 添加原始文本（在清理之前，以便清理函数可以访问）
            json_output["raw_text"] = ocr_text

            # 清理数据（移除货币符号和单位）
            json_output = self._clean_output(json_output)

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

    def _clean_output(self, data: dict) -> dict:
        """
        清理 LLM 输出，移除货币符号和单位

        Args:
            data: LLM 输出的字典

        Returns:
            清理后的字典
        """
        import re
        from datetime import datetime

        def clean_number(value):
            """清理数字字符串"""
            if value is None:
                return None
            if isinstance(value, (int, float)):
                return value
            if isinstance(value, str):
                # 移除货币符号: ￥ ¥ $ €
                value = re.sub(r'[￥¥$€]', '', value)
                # 移除单位: × x 份 件 个
                value = re.sub(r'[×x份件个]', '', value)
                # 移除空格
                value = value.strip()
                # 尝试转换为数字
                try:
                    return float(value) if '.' in value else int(value)
                except:
                    return None
            return None

        # 清理顶层金额字段
        for field in ['total_amount', 'subtotal', 'tax_amount']:
            if field in data and data[field]:
                data[field] = clean_number(data[field])

        # 清理商品列表
        if 'items' in data and isinstance(data['items'], list):
            for item in data['items']:
                if isinstance(item, dict):
                    for field in ['quantity', 'unit_price', 'amount']:
                        if field in item and item[field]:
                            item[field] = clean_number(item[field])

            # 去重：只删除明确是规格说明的项（包含特定关键词）
            if len(data['items']) > 1:
                deduplicated = []
                for item in data['items']:
                    name = item.get('name', '')
                    # 如果商品名包含"份量"、"口味"等关键词，这是说明不是商品
                    if any(keyword in name for keyword in ['份量', '口味', '备注', '规格', '加料', '温度']):
                        continue
                    deduplicated.append(item)

                # 如果去重后还有商品，使用去重后的列表
                if deduplicated:
                    data['items'] = deduplicated

        # 修复总金额：优先从原始文本提取"合计/实付/应付"（更可靠）
        if 'total_amount' in data:
            raw_text = data.get('raw_text', '')

            # 始终尝试从原始文本提取总金额（比 LLM 计算更准确）
            extracted_amount = None

            # 按优先级尝试提取: 实付 > 应付 > 合计
            # (实付最准确，合计可能被误匹配为"优惠合计")
            if extracted_amount is None:
                patterns = [
                    r'实付[：:\s]*[￥¥]?([\d.]+)',  # 实付: ¥9.9
                    r'应付[：:\s]*[￥¥]?([\d.]+)',  # 应付: ¥34.6
                ]
                for pattern in patterns:
                    matches = re.findall(pattern, raw_text)
                    if matches:
                        extracted_amount = float(matches[-1])
                        break

            # 如果还没找到，尝试"合计"（需要特殊处理，避免误匹配"优惠合计"）
            if extracted_amount is None:
                # 只匹配不是以"优惠"开头的"合计"
                match = re.search(r'(?<!优惠)(?<!优惠券)(?<!优惠减免)合计[^\n]*\n[^\n]*', raw_text)
                if match:
                    section = match.group()
                    numbers = re.findall(r'[¥￥]([\d.]+)', section)
                    if numbers:
                        extracted_amount = float(numbers[-1])

            # 如果从文本提取成功，优先使用提取的金额
            if extracted_amount is not None and extracted_amount > 0:
                data['total_amount'] = extracted_amount
            # 否则，如果 LLM 返回的金额有问题（负数或 None），使用商品总价
            elif data['total_amount'] is None or (isinstance(data['total_amount'], (int, float)) and data['total_amount'] <= 0):
                if 'items' in data and data['items']:
                    total = sum(item.get('amount', 0) or 0 for item in data['items'])
                    if total > 0:
                        data['total_amount'] = total

        # 如果没有提取到日期，使用当前系统时间
        if 'invoice_date' not in data or not data['invoice_date']:
            data['invoice_date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        return data

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
