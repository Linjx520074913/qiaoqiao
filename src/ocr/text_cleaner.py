"""
OCR 文本清理工具
移除无关内容，提升 LLM 处理速度和准确性
"""

import re
from typing import List


class OCRTextCleaner:
    """OCR 文本清理器"""

    # 常见的 UI 元素（可以安全删除）
    UI_ELEMENTS = {
        # 按钮和链接
        '收藏', '分享', '删除', '编辑', '复制', '保存',
        '联系客服', '客服', '在线客服', '咨询',
        '开发票', '发票助手', '查看发票',
        '再来一单', '再次购买', '立即购买',
        '去支付', '立即支付', '确认支付',
        '查看详情', '订单详情', '查看更多', '展开', '收起',
        '点击收起', '点击展开',

        # 导航元素
        '返回', '< 返回', '首页', '我的',
        '>', '<', '»', '«',

        # 提示信息
        '温馨提示', '小贴士', '注意事项',
        '已读', '未读',

        # 广告和营销
        '立即领取', '马上抢', '限时优惠',
        '新人专享', '会员专享',

        # 空白标记
        '...', '···', '...',
    }

    # 问题解决相关（保留，但可能无用）
    QUESTION_PATTERNS = [
        r'.*怎么办[？?]?$',
        r'^更多$',
        r'^恭喜.*',
        r'.*机会.*试试.*',
    ]

    # 完全无意义的短行（1-2个字符）
    MEANINGLESS_PATTERNS = [
        r'^[a-zA-Z]{1,2}$',  # 单个字母
        r'^[><!@#$%^&*()_+=\-]{1,3}$',  # 单个符号
        r'^[\u4e00-\u9fff]{1}$',  # 单个汉字（保留2+字）
    ]

    # 无关信息模式
    IRRELEVANT_PATTERNS = [
        r'^\d{1,2}:\d{2}$',  # 时间 (11:36)
        r'^取餐码\d+$',       # 取餐码
        r'^[A-Z]{2,3}$',     # CN, m 等缩写
        r'^\d{1,2}$',        # 纯数字（如 29）
    ]

    def __init__(self, aggressive: bool = False, format_text: bool = False):
        """
        初始化清理器

        Args:
            aggressive: 激进模式（删除更多内容，可能影响准确性）
            format_text: 文本格式化模式（合并商品信息，提升 LLM 理解速度）
        """
        self.aggressive = aggressive
        self.format_text = format_text

    def clean(self, text: str) -> str:
        """
        清理 OCR 文本

        Args:
            text: 原始 OCR 文本

        Returns:
            清理后的文本
        """
        lines = text.split('\n')
        cleaned_lines = []

        for line in lines:
            line = line.strip()

            # 跳过空行
            if not line:
                continue

            # 移除注释标记（箭头）
            line = re.sub(r'\s*[←→↑↓]\s*.*$', '', line)

            # 跳过 UI 元素
            if line in self.UI_ELEMENTS:
                continue

            # 跳过问题解决相关（激进模式）
            if self.aggressive:
                if any(re.match(pattern, line) for pattern in self.QUESTION_PATTERNS):
                    continue

            # 跳过完全无意义的短行
            if any(re.match(pattern, line) for pattern in self.MEANINGLESS_PATTERNS):
                continue

            # 跳过无关信息（时间、取餐码等）
            if any(re.match(pattern, line) for pattern in self.IRRELEVANT_PATTERNS):
                continue

            cleaned_lines.append(line)

        # 重新组合，移除多余空行
        cleaned_text = '\n'.join(cleaned_lines)

        # 合并多个连续换行
        cleaned_text = re.sub(r'\n{3,}', '\n\n', cleaned_text)

        # 文本格式化（可选）
        if self.format_text:
            cleaned_text = self._format_text(cleaned_text)

        return cleaned_text.strip()

    def _format_text(self, text: str) -> str:
        """
        格式化文本，合并商品信息行

        将分散的商品信息（名称、数量、金额）合并到同一行
        例如：
        原味板烧鸡腿麦满分组合
        1×小杯鲜萃咖啡
        1份
        ￥17

        合并为：
        原味板烧鸡腿麦满分组合 1份 ￥17
        """
        lines = text.split('\n')
        formatted_lines = []
        i = 0

        while i < len(lines):
            line = lines[i].strip()

            # 检查是否是商品名称行（长度 > 4 且不包含金额符号）
            if len(line) > 4 and '￥' not in line and not re.match(r'^\d+[×x]', line):
                # 尝试合并后续的数量和金额行
                merged = line
                j = i + 1

                # 向前看最多 4 行，收集数量和金额信息
                quantity_found = False
                amount_found = False

                while j < min(i + 5, len(lines)) and (not quantity_found or not amount_found):
                    next_line = lines[j].strip()

                    # 跳过商品详情行（如 "1×小杯鲜萃咖啡"）
                    if re.match(r'^\d+[×x]', next_line) and len(next_line) > 4:
                        j += 1
                        continue

                    # 查找数量（如 "1份", "2个"）
                    if not quantity_found and re.search(r'^\d+[份个件]$', next_line):
                        merged += ' ' + next_line
                        quantity_found = True
                        j += 1
                        continue

                    # 查找金额（如 "￥17", "17.5"）
                    if not amount_found and (next_line.startswith('￥') or re.match(r'^\d+\.?\d*$', next_line)):
                        # 确保是合理的金额（不是年份等）
                        if next_line.startswith('￥') or (len(next_line) <= 6 and '.' in next_line):
                            merged += ' ' + next_line
                            amount_found = True
                            j += 1
                            continue

                    # 如果当前行看起来是新的商品名称或关键字段，停止合并
                    if len(next_line) > 4 or next_line in ['商品小计', '合计', '总计', '实付', '应付']:
                        break

                    j += 1

                formatted_lines.append(merged)
                i = j
            else:
                # 不是商品名称行，直接添加
                formatted_lines.append(line)
                i += 1

        return '\n'.join(formatted_lines)

    def get_stats(self, original: str, cleaned: str) -> dict:
        """
        获取清理统计信息

        Args:
            original: 原始文本
            cleaned: 清理后文本

        Returns:
            统计信息字典
        """
        original_lines = len(original.split('\n'))
        cleaned_lines = len(cleaned.split('\n'))
        original_chars = len(original)
        cleaned_chars = len(cleaned)

        return {
            'original_lines': original_lines,
            'cleaned_lines': cleaned_lines,
            'removed_lines': original_lines - cleaned_lines,
            'line_reduction': (original_lines - cleaned_lines) / original_lines * 100,
            'original_chars': original_chars,
            'cleaned_chars': cleaned_chars,
            'removed_chars': original_chars - cleaned_chars,
            'char_reduction': (original_chars - cleaned_chars) / original_chars * 100,
        }


def clean_ocr_text(text: str, aggressive: bool = False, format_text: bool = False) -> str:
    """
    便捷函数：清理 OCR 文本

    Args:
        text: 原始 OCR 文本
        aggressive: 激进模式
        format_text: 文本格式化模式（合并商品信息）

    Returns:
        清理后的文本
    """
    cleaner = OCRTextCleaner(aggressive=aggressive, format_text=format_text)
    return cleaner.clean(text)
