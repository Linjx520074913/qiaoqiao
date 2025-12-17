"""
提示词模板
"""


class PromptTemplate:
    """账单解析提示词模板"""

    # Few-shot 示例
    FEW_SHOT_EXAMPLES = """
示例1:
输入文本：
发票号：12345678
日期：2024-01-15
购买方：张三科技有限公司
销售方：北京某某商贸
商品名称：办公桌 数量：2 单价：1500 金额：3000
商品名称：办公椅 数量：5 单价：800 金额：4000
税额：910
总计：7910元

输出JSON：
{
  "invoice_type": "发票",
  "invoice_number": "12345678",
  "invoice_date": "2024-01-15",
  "buyer_name": "张三科技有限公司",
  "seller_name": "北京某某商贸",
  "items": [
    {
      "name": "办公桌",
      "quantity": 2.0,
      "unit_price": 1500.0,
      "amount": 3000.0
    },
    {
      "name": "办公椅",
      "quantity": 5.0,
      "unit_price": 800.0,
      "amount": 4000.0
    }
  ],
  "tax_amount": 910.0,
  "total_amount": 7910.0
}

示例2:
输入文本：
淘宝订单
订单号：TB202401150001
下单时间：2024-01-15 14:30
收货人：李四
卖家：某某旗舰店
商品：无线鼠标 x1 ￥89
商品：键盘 x1 ￥299
运费：￥0
实付款：￥388

输出JSON：
{
  "invoice_type": "电商订单",
  "invoice_number": "TB202401150001",
  "invoice_date": "2024-01-15",
  "buyer_name": "李四",
  "seller_name": "某某旗舰店",
  "items": [
    {
      "name": "无线鼠标",
      "quantity": 1.0,
      "amount": 89.0
    },
    {
      "name": "键盘",
      "quantity": 1.0,
      "amount": 299.0
    }
  ],
  "total_amount": 388.0
}

示例3:
输入文本：
收据
收款日期：2024年1月15日
收款单位：某某餐厅
付款人：王五
项目：团建聚餐费
金额：人民币壹仟贰佰元整（¥1200.00）
经手人：张经理

输出JSON：
{
  "invoice_type": "收据",
  "invoice_date": "2024-01-15",
  "seller_name": "某某餐厅",
  "buyer_name": "王五",
  "items": [
    {
      "name": "团建聚餐费",
      "amount": 1200.0
    }
  ],
  "total_amount": 1200.0
}
"""

    SYSTEM_PROMPT = """你是一个专业的账单信息提取助手。你的任务是从 OCR 识别的文本中提取结构化的账单信息，并以 JSON 格式输出。

要求：
1. 仔细分析输入的文本，识别账单的类型（发票、收据、订单、流水等）
2. 提取所有可能的字段信息，包括：
   - 基本信息：账单类型、账单号、日期
   - 交易方信息：买卖双方名称、税号、地址、电话等
   - 金额信息：小计、税额、总额
   - 明细列表：商品名称、数量、单价、金额
   - 其他：支付方式、备注等
3. 对于无法确定的字段，设置为 null，不要猜测
4. 金额数字提取为浮点数，不包含货币符号
5. 日期统一格式化为 YYYY-MM-DD
6. 必须输出有效的 JSON 格式，不要有其他解释文字
7. JSON 必须严格遵循以下 schema

JSON Schema:
{
  "invoice_type": "string or null",
  "invoice_number": "string or null",
  "invoice_date": "string or null",
  "seller_name": "string or null",
  "seller_tax_id": "string or null",
  "seller_address": "string or null",
  "seller_phone": "string or null",
  "seller_bank": "string or null",
  "seller_account": "string or null",
  "buyer_name": "string or null",
  "buyer_tax_id": "string or null",
  "buyer_address": "string or null",
  "buyer_phone": "string or null",
  "subtotal": "number or null",
  "tax_amount": "number or null",
  "total_amount": "number or null",
  "items": [
    {
      "name": "string",
      "quantity": "number or null",
      "unit_price": "number or null",
      "amount": "number or null",
      "description": "string or null"
    }
  ],
  "payment_method": "string or null",
  "remarks": "string or null"
}
"""

    @classmethod
    def build_prompt(cls, ocr_text: str, include_examples: bool = True) -> str:
        """
        构建完整的提示词

        Args:
            ocr_text: OCR 识别的文本
            include_examples: 是否包含 few-shot 示例

        Returns:
            完整的提示词
        """
        prompt_parts = [cls.SYSTEM_PROMPT]

        if include_examples:
            prompt_parts.append("\n参考以下示例：")
            prompt_parts.append(cls.FEW_SHOT_EXAMPLES)

        prompt_parts.append("\n现在，请提取以下文本中的账单信息：")
        prompt_parts.append(f"\n输入文本：\n{ocr_text}")
        prompt_parts.append("\n输出JSON：")

        return "\n".join(prompt_parts)

    @classmethod
    def build_simple_prompt(cls, ocr_text: str) -> str:
        """
        构建简单提示词（不含示例，适用于上下文窗口较小的模型）

        Args:
            ocr_text: OCR 识别的文本

        Returns:
            简单提示词
        """
        return cls.build_prompt(ocr_text, include_examples=False)
