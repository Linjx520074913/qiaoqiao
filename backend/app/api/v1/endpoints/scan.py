"""
账单扫描API端点
"""
import os
import sys
import time
from pathlib import Path
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
import tempfile

# 添加引擎路径到sys.path
ENGINE_PATH = Path(__file__).parent.parent.parent.parent.parent / "engine"
sys.path.insert(0, str(ENGINE_PATH))

from src.ocr import RapidOCREngine
from src.llm import OllamaEngine
from src.parser import SmartParser, MultiOrderParser
from src.ocr.text_cleaner import clean_ocr_text

from app.schemas.invoice import ScanResponse, Invoice as InvoiceSchema, InvoiceItem
from app.core.config import settings

router = APIRouter()

# 全局变量（缓存引擎实例）
ocr_engine: Optional[RapidOCREngine] = None
llm_engine: Optional[OllamaEngine] = None


def get_ocr_engine(use_angle_cls: bool = False) -> RapidOCREngine:
    """获取OCR引擎实例"""
    global ocr_engine
    if ocr_engine is None or ocr_engine.use_angle_cls != use_angle_cls:
        ocr_engine = RapidOCREngine(use_angle_cls=use_angle_cls)
    return ocr_engine


def get_llm_engine() -> OllamaEngine:
    """获取LLM引擎实例"""
    global llm_engine
    if llm_engine is None:
        llm_engine = OllamaEngine(model_name=settings.LLM_MODEL)
    return llm_engine


@router.post("/scan", response_model=ScanResponse)
async def scan_bill(
    file: UploadFile = File(...),
    use_angle_cls: bool = Form(False),
    clean_text: bool = Form(False),
    format_text: bool = Form(False),
    skip_items: bool = Form(False),
    concurrent: bool = Form(False),
):
    """
    扫描账单图片

    Args:
        file: 图片文件
        use_angle_cls: 是否使用角度分类
        clean_text: 是否清理文本
        format_text: 是否格式化文本
        skip_items: 是否跳过商品明细
        concurrent: 是否并发处理订单列表

    Returns:
        扫描结果
    """
    start_time = time.time()
    times = {}

    try:
        # 1. 验证文件
        if not file.filename:
            raise HTTPException(status_code=400, detail="未提供文件")

        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in settings.ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"不支持的文件格式: {file_ext}。支持的格式: {', '.join(settings.ALLOWED_EXTENSIONS)}"
            )

        # 2. 保存临时文件
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp_file:
            content = await file.read()
            if len(content) > settings.MAX_UPLOAD_SIZE:
                raise HTTPException(
                    status_code=400,
                    detail=f"文件过大。最大支持: {settings.MAX_UPLOAD_SIZE / (1024*1024):.0f}MB"
                )
            tmp_file.write(content)
            tmp_path = tmp_file.name

        try:
            # 3. OCR识别
            t = time.time()
            ocr = get_ocr_engine(use_angle_cls)
            image = Image.open(tmp_path)
            ocr_result = ocr.extract_text(image)
            times['ocr'] = time.time() - t

            # 4. 文本清理/格式化
            if clean_text or format_text:
                original_len = len(ocr_result.text)
                ocr_result.text = clean_ocr_text(ocr_result.text, format_text=format_text)
                times['clean'] = time.time() - t - times['ocr']

            # 5. 初始化LLM
            t = time.time()
            llm = get_llm_engine()
            times['llm_init'] = time.time() - t

            # 6. 检测订单类型
            t = time.time()
            multi_parser = MultiOrderParser(llm, skip_items=skip_items)
            is_list, list_conf = multi_parser.is_order_list(ocr_result.text)
            times['detect'] = time.time() - t

            # 7. 解析账单
            t = time.time()
            if is_list:
                # 订单列表处理
                order_blocks = multi_parser.split_orders(ocr_result.text)
                results, stats = multi_parser.parse_order_list(ocr_result.text)
                times['parse'] = time.time() - t

                # 转换为响应格式
                invoices = []
                for result in results:
                    if result.success and result.invoice:
                        inv_dict = result.invoice.model_dump(exclude_none=True)
                        invoices.append(InvoiceSchema(**inv_dict))

                times['total'] = time.time() - start_time

                return ScanResponse(
                    success=True,
                    message="订单列表识别成功",
                    invoices=invoices,
                    is_list=True,
                    stats=stats,
                    performance=times
                )
            else:
                # 单个订单处理
                parser = SmartParser(llm, skip_items=skip_items)
                result = parser.parse(ocr_result.text)
                times['parse'] = time.time() - t

                if not result.success:
                    raise HTTPException(status_code=500, detail=result.error_message or "解析失败")

                # 转换为响应格式
                inv_dict = result.invoice.model_dump(exclude_none=True)
                invoice = InvoiceSchema(**inv_dict)

                times['total'] = time.time() - start_time

                return ScanResponse(
                    success=True,
                    message="账单识别成功",
                    invoice=invoice,
                    is_list=False,
                    performance=times
                )

        finally:
            # 清理临时文件
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"处理失败: {str(e)}")


@router.get("/health")
async def health_check():
    """健康检查"""
    try:
        # 检查引擎状态
        ocr = get_ocr_engine()
        llm = get_llm_engine()

        return {
            "status": "healthy",
            "version": settings.APP_VERSION,
            "engine_status": "ok",
            "ocr_engine": "RapidOCR",
            "llm_model": settings.LLM_MODEL
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "version": settings.APP_VERSION,
                "engine_status": "error",
                "error": str(e)
            }
        )
