#!/usr/bin/env python3
"""
KAPI HTTP Server - 基于 FastAPI 的账单识别服务
"""

import sys
import os
import time
import logging
import tempfile
import uuid
from pathlib import Path
from typing import Optional, Dict, Any, List
from concurrent.futures import ThreadPoolExecutor, as_completed

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# 添加 engine 到路径
ENGINE_PATH = Path(__file__).parent.parent / "engine"
sys.path.insert(0, str(ENGINE_PATH))

from src.ocr import RapidOCREngine, clean_ocr_text
from src.llm import OllamaEngine
from src.parser.smart_parser import SmartParser
from src.parser.multi_order_parser import MultiOrderParser
from src.parser.fast_parser import FastBillParser
from src.parser.bank_parser import BankStatementParser

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# ==================== 数据模型 ====================

class ScanRequest(BaseModel):
    """扫描请求（非文件上传时使用）"""
    image_path: str


class ScanResponse(BaseModel):
    """扫描响应"""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    performance: Optional[Dict[str, float]] = None


class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str
    version: str
    components: Dict[str, bool]


# ==================== FastAPI 应用 ====================

app = FastAPI(
    title="KAPI - 智能账单识别服务",
    description="基于 OCR + LLM 的账单识别 HTTP API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== 全局变量 ====================

# 临时文件目录
TEMP_DIR = Path(tempfile.gettempdir()) / "kapi_uploads"
TEMP_DIR.mkdir(exist_ok=True, parents=True)

# 默认配置
DEFAULT_MODEL = "qwen2.5:3b"
FAST_MODEL = "qwen2.5:1.5b"

# 引擎实例（延迟初始化）
ocr_engine = None
llm_engine = None


# ==================== 工具函数 ====================

def init_engines(model: str = DEFAULT_MODEL, use_angle_cls: bool = True):
    """初始化 OCR 和 LLM 引擎"""
    global ocr_engine, llm_engine

    if ocr_engine is None:
        ocr_engine = RapidOCREngine(use_angle_cls=use_angle_cls, print_verbose=False)
        logger.info("OCR engine initialized")

    if llm_engine is None or llm_engine.model_name != model:
        llm_engine = OllamaEngine(model_name=model, temperature=0.0, max_tokens=512)
        logger.info(f"LLM engine initialized: {model}")

    return ocr_engine, llm_engine


def scan_image(
    image_path: str,
    model: str = DEFAULT_MODEL,
    skip_items: bool = False,
    clean_text: bool = False,
    format_text: bool = False,
    concurrent: bool = False,
    use_angle_cls: bool = True,
) -> Dict[str, Any]:
    """
    扫描图片

    Args:
        image_path: 图片路径
        model: LLM 模型
        skip_items: 跳过商品明细
        clean_text: 清理文本
        format_text: 格式化文本
        concurrent: 并发处理
        use_angle_cls: 角度检测

    Returns:
        扫描结果字典
    """
    if not Path(image_path).exists():
        return {"success": False, "error": f"文件不存在: {image_path}"}

    times = {}
    total_start = time.time()

    try:
        # 初始化引擎
        ocr, llm = init_engines(model, use_angle_cls)

        # Step 1: OCR 提取
        logger.info("OCR extracting...")
        t = time.time()
        ocr_result = ocr.extract_text(image_path)
        times["ocr"] = time.time() - t

        if not ocr_result.success:
            return {
                "success": False,
                "error": f"OCR failed: {ocr_result.error_message}",
                "performance": times,
            }

        # 文本处理
        if clean_text or format_text:
            ocr_result.text = clean_ocr_text(ocr_result.text, format_text=format_text)

        # Step 2: 检测类型
        logger.info("Detecting type...")
        t = time.time()
        multi_parser = MultiOrderParser(llm, skip_items=skip_items)
        is_list, list_conf = multi_parser.is_order_list(ocr_result.text)
        times["detect_type"] = time.time() - t

        # Step 3: 解析
        if is_list:
            # 订单列表
            logger.info(f"Order list detected (conf: {list_conf:.2%})")
            t = time.time()
            order_blocks = multi_parser.split_orders(ocr_result.text)
            times["split"] = time.time() - t

            t = time.time()
            is_bank = multi_parser._is_bank_statement_list(ocr_result.text)

            if concurrent and len(order_blocks) > 1:
                results, stats = parse_concurrent(order_blocks, llm, is_bank, skip_items)
            else:
                results, stats = multi_parser.parse_order_list(ocr_result.text)

            times["parse"] = time.time() - t
            times["total"] = time.time() - total_start

            return {
                "success": True,
                "data": {
                    "type": "order_list",
                    "total_orders": stats["total_orders"],
                    "stats": stats,
                    "orders": [r.model_dump(exclude_none=True) if r.success else {"success": False, "error": r.error_message} for r in results],
                },
                "performance": times,
            }
        else:
            # 单个订单
            logger.info("Single order detected")
            t = time.time()
            parser = SmartParser(llm, skip_items=skip_items)
            result = parser.parse(ocr_result.text)
            times["parse"] = time.time() - t
            times["total"] = time.time() - total_start

            if not result.success:
                return {
                    "success": False,
                    "error": result.error_message,
                    "performance": times,
                }

            return {
                "success": True,
                "data": {
                    "type": "single_order",
                    "invoice": result.invoice.model_dump(exclude_none=True) if result.invoice else None,
                    "confidence": result.confidence,
                },
                "performance": times,
            }

    except Exception as e:
        logger.error(f"Scan failed: {e}", exc_info=True)
        times["total"] = time.time() - total_start
        return {
            "success": False,
            "error": str(e),
            "performance": times,
        }


def parse_concurrent(order_blocks, llm, is_bank, skip_items):
    """并发解析订单"""
    results = []
    stats = {
        "total_orders": len(order_blocks),
        "completed": 0,
        "cancelled": 0,
        "in_progress": 0,
        "other": 0,
    }

    def parse_one(block):
        if is_bank:
            parser = BankStatementParser()
            result = parser.parse(block.text)
        else:
            parser = FastBillParser(llm, skip_items=skip_items)
            result = parser.parse(block.text)

        if result.success and result.invoice:
            if not result.invoice.remarks:
                result.invoice.remarks = f"订单状态: {block.status}"
            else:
                result.invoice.remarks += f" | 订单状态: {block.status}"

        return result, block.status

    with ThreadPoolExecutor(max_workers=min(len(order_blocks), 4)) as executor:
        futures = {executor.submit(parse_one, block): i for i, block in enumerate(order_blocks)}
        temp_results = [None] * len(order_blocks)

        for future in as_completed(futures):
            idx = futures[future]
            result, status = future.result()
            temp_results[idx] = (result, status)

        for result, status in temp_results:
            results.append(result)
            if status == "已完成":
                stats["completed"] += 1
            elif status == "已取消":
                stats["cancelled"] += 1
            elif status in ["进行中", "待支付", "待发货", "待收货"]:
                stats["in_progress"] += 1
            else:
                stats["other"] += 1

    return results, stats


# ==================== API 端点 ====================

@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "KAPI - 智能账单识别服务",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """健康检查"""
    components = {}

    try:
        ocr, llm = init_engines()
        components["ocr"] = True
        components["llm"] = True
        status = "healthy"
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        components["ocr"] = False
        components["llm"] = False
        status = "unhealthy"

    return HealthResponse(
        status=status,
        version="1.0.0",
        components=components,
    )


@app.post("/scan", response_model=ScanResponse)
async def scan_bill(
    file: UploadFile = File(..., description="账单图片"),
    skip_items: bool = Form(False, description="跳过商品明细"),
    clean_text: bool = Form(False, description="清理文本"),
    format_text: bool = Form(False, description="格式化文本"),
    concurrent: bool = Form(False, description="并发处理"),
    use_angle_cls: bool = Form(True, description="角度检测"),
    model: Optional[str] = Form(None, description="LLM 模型"),
):
    """
    扫描账单（标准模式）

    - **file**: 账单图片
    - **skip_items**: 跳过商品明细（提升 50% 速度）
    - **clean_text**: 清理 OCR 文本（提升 5-10% 速度）
    - **format_text**: 格式化文本（提升 20-30% 速度，可能漏项）
    - **concurrent**: 并发解析订单列表
    - **use_angle_cls**: OCR 角度检测
    - **model**: LLM 模型（默认 qwen2.5:3b）
    """
    # 检查文件类型
    allowed_ext = {".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp"}
    file_ext = Path(file.filename).suffix.lower()

    if file_ext not in allowed_ext:
        raise HTTPException(
            status_code=400,
            detail=f"不支持的文件类型: {file_ext}",
        )

    # 保存临时文件
    temp_file_id = str(uuid.uuid4())
    temp_file_path = TEMP_DIR / f"{temp_file_id}{file_ext}"

    try:
        contents = await file.read()

        # 检查文件大小（10MB）
        if len(contents) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail=f"文件太大: {len(contents)} bytes (max: 10MB)",
            )

        with open(temp_file_path, "wb") as f:
            f.write(contents)

        logger.info(f"File uploaded: {file.filename}")

        # 扫描
        result = scan_image(
            image_path=str(temp_file_path),
            model=model or DEFAULT_MODEL,
            skip_items=skip_items,
            clean_text=clean_text,
            format_text=format_text,
            concurrent=concurrent,
            use_angle_cls=use_angle_cls,
        )

        return ScanResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 清理
        if temp_file_path.exists():
            os.remove(temp_file_path)


@app.post("/scan/fast", response_model=ScanResponse)
async def scan_bill_fast(
    file: UploadFile = File(..., description="账单图片"),
    concurrent: bool = Form(True, description="并发处理"),
    skip_items: bool = Form(False, description="跳过商品明细"),
):
    """
    快速扫描（预设优化参数）

    - 使用 qwen2.5:1.5b 小模型
    - 关闭角度检测
    - 可选跳过商品明细
    - 速度: 3-4 秒（包含明细），2-3 秒（跳过明细）
    """
    return await scan_bill(
        file=file,
        skip_items=skip_items,
        clean_text=False,
        format_text=False,
        concurrent=concurrent,
        use_angle_cls=False,
        model=FAST_MODEL,
    )


# ==================== 启动 ====================

if __name__ == "__main__":
    import uvicorn

    logger.info("=" * 60)
    logger.info("KAPI HTTP Server Starting...")
    logger.info("=" * 60)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info",
    )
