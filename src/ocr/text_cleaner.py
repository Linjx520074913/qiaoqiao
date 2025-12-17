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

    def __init__(self, aggressive: bool = False):
        """
        初始化清理器

        Args:
            aggressive: 激进模式（删除更多内容，可能影响准确性）
        """
        self.aggressive = aggressive

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

            cleaned_lines.append(line)

        # 重新组合，移除多余空行
        cleaned_text = '\n'.join(cleaned_lines)

        # 合并多个连续换行
        cleaned_text = re.sub(r'\n{3,}', '\n\n', cleaned_text)

        return cleaned_text.strip()

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


def clean_ocr_text(text: str, aggressive: bool = False) -> str:
    """
    便捷函数：清理 OCR 文本

    Args:
        text: 原始 OCR 文本
        aggressive: 激进模式

    Returns:
        清理后的文本
    """
    cleaner = OCRTextCleaner(aggressive=aggressive)
    return cleaner.clean(text)
