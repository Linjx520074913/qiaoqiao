"""
OCR 模块 - 支持多种 OCR 引擎
"""

from .rapid_ocr import RapidOCREngine, OCRResult
from .text_cleaner import OCRTextCleaner, clean_ocr_text

__all__ = ["RapidOCREngine", "OCRResult", "OCRTextCleaner", "clean_ocr_text"]
