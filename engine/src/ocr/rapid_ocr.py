"""
RapidOCR 引擎封装
支持图片文本识别，专为账单场景优化
"""

from typing import Optional, List, Dict, Any, Union
from pathlib import Path
from dataclasses import dataclass
import numpy as np
from PIL import Image


@dataclass
class OCRResult:
    """OCR 识别结果"""

    text: str  # 完整文本
    boxes: List[List[float]]  # 文字框坐标
    scores: List[float]  # 置信度
    lines: List[str]  # 按行分割的文本
    success: bool = True
    error_message: Optional[str] = None

    @property
    def avg_score(self) -> float:
        """平均置信度"""
        if not self.scores:
            return 0.0
        return sum(self.scores) / len(self.scores)

    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "text": self.text,
            "lines": self.lines,
            "boxes_count": len(self.boxes),
            "avg_score": self.avg_score,
            "success": self.success,
            "error_message": self.error_message,
        }


class RapidOCREngine:
    """
    RapidOCR 引擎封装
    支持图片文本识别，优化账单场景
    """

    def __init__(
        self,
        use_angle_cls: bool = True,
        use_text_det: bool = True,
        use_text_rec: bool = True,
        print_verbose: bool = False,
    ):
        """
        初始化 RapidOCR 引擎

        Args:
            use_angle_cls: 是否使用角度分类器（识别文字方向）
            use_text_det: 是否使用文字检测
            use_text_rec: 是否使用文字识别
            print_verbose: 是否打印详细信息
        """
        try:
            from rapidocr_onnxruntime import RapidOCR
        except ImportError:
            raise ImportError(
                "RapidOCR not installed. Please install: pip install rapidocr-onnxruntime"
            )

        self.engine = RapidOCR(
            det_use_cuda=False,  # 使用 CPU，可根据需要改为 True
            cls_use_cuda=False,
            rec_use_cuda=False,
            det_model_path=None,  # 使用默认模型
            cls_model_path=None,
            rec_model_path=None,
        )

        self.use_angle_cls = use_angle_cls
        self.use_text_det = use_text_det
        self.use_text_rec = use_text_rec
        self.print_verbose = print_verbose

    def extract_text(
        self,
        image_path: Union[str, Path],
        merge_lines: bool = True,
        line_separator: str = "\n",
    ) -> OCRResult:
        """
        从图片中提取文本

        Args:
            image_path: 图片路径
            merge_lines: 是否合并所有行为一个文本
            line_separator: 行分隔符（当 merge_lines=True 时使用）

        Returns:
            OCRResult: 识别结果
        """
        try:
            # 读取图片
            image_path = Path(image_path)
            if not image_path.exists():
                return OCRResult(
                    text="",
                    boxes=[],
                    scores=[],
                    lines=[],
                    success=False,
                    error_message=f"Image file not found: {image_path}",
                )

            # 使用 PIL 读取图片
            img = Image.open(image_path)
            img_array = np.array(img)

            # 进行 OCR 识别
            result, elapse = self.engine(img_array)

            if self.print_verbose:
                print(f"OCR elapsed time: {elapse:.3f}s")

            # 解析结果
            if result is None or len(result) == 0:
                return OCRResult(
                    text="",
                    boxes=[],
                    scores=[],
                    lines=[],
                    success=True,
                    error_message="No text detected in image",
                )

            # RapidOCR 返回格式: [[box, text, score], ...]
            boxes = []
            texts = []
            scores = []

            for item in result:
                box, text, score = item
                boxes.append(box)
                texts.append(text)
                scores.append(float(score))

            # 合并文本
            if merge_lines:
                full_text = line_separator.join(texts)
            else:
                full_text = " ".join(texts)

            return OCRResult(
                text=full_text,
                boxes=boxes,
                scores=scores,
                lines=texts,
                success=True,
            )

        except Exception as e:
            return OCRResult(
                text="",
                boxes=[],
                scores=[],
                lines=[],
                success=False,
                error_message=f"OCR failed: {str(e)}",
            )

    def extract_from_bytes(
        self,
        image_bytes: bytes,
        merge_lines: bool = True,
        line_separator: str = "\n",
    ) -> OCRResult:
        """
        从图片字节流中提取文本

        Args:
            image_bytes: 图片字节流
            merge_lines: 是否合并所有行为一个文本
            line_separator: 行分隔符

        Returns:
            OCRResult: 识别结果
        """
        try:
            from io import BytesIO

            # 从字节流读取图片
            img = Image.open(BytesIO(image_bytes))
            img_array = np.array(img)

            # 进行 OCR 识别
            result, elapse = self.engine(img_array)

            if self.print_verbose:
                print(f"OCR elapsed time: {elapse:.3f}s")

            # 解析结果
            if result is None or len(result) == 0:
                return OCRResult(
                    text="",
                    boxes=[],
                    scores=[],
                    lines=[],
                    success=True,
                    error_message="No text detected in image",
                )

            # RapidOCR 返回格式: [[box, text, score], ...]
            boxes = []
            texts = []
            scores = []

            for item in result:
                box, text, score = item
                boxes.append(box)
                texts.append(text)
                scores.append(float(score))

            # 合并文本
            if merge_lines:
                full_text = line_separator.join(texts)
            else:
                full_text = " ".join(texts)

            return OCRResult(
                text=full_text,
                boxes=boxes,
                scores=scores,
                lines=texts,
                success=True,
            )

        except Exception as e:
            return OCRResult(
                text="",
                boxes=[],
                scores=[],
                lines=[],
                success=False,
                error_message=f"OCR failed: {str(e)}",
            )

    def batch_extract(
        self,
        image_paths: List[Union[str, Path]],
        merge_lines: bool = True,
    ) -> List[OCRResult]:
        """
        批量提取文本

        Args:
            image_paths: 图片路径列表
            merge_lines: 是否合并行

        Returns:
            List[OCRResult]: 识别结果列表
        """
        results = []
        for image_path in image_paths:
            result = self.extract_text(image_path, merge_lines=merge_lines)
            results.append(result)
        return results

    def test_connection(self) -> bool:
        """
        测试 OCR 引擎是否可用

        Returns:
            bool: 是否可用
        """
        try:
            # 创建一个小测试图片
            test_img = np.ones((100, 100, 3), dtype=np.uint8) * 255
            result, _ = self.engine(test_img)
            return True
        except Exception as e:
            if self.print_verbose:
                print(f"OCR engine test failed: {e}")
            return False
