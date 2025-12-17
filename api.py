#!/usr/bin/env python3
"""
KAPI - 智能账单识别 API 服务
基于 FastAPI 提供 HTTP 接口
"""

import os
import time
import tempfile
import logging
from pathlib import Path
from typing import Optional, List
from concurrent.futures import ThreadPoolExecutor, as_completed

from fastapi import FastAPI, File, UploadFile, Query, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from src.ocr import RapidOCREngine
from src.llm import OllamaEngine
from src.parser.smart_parser import SmartParser
from src.parser.multi_order_parser import MultiOrderParser
from src.parser.fast_parser import FastBillParser
from src.parser.bank_parser import BankStatementParser

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建 FastAPI 应用
app = FastAPI(
    title="KAPI - 智能账单识别",
    description="支持餐饮订单、电商订单、银行流水、发票等多种账单类型的智能识别",
    version="2.0.0"
)


# 响应模型
class InvoiceItem(BaseModel):
    """账单项目"""
    name: str
    quantity: Optional[float] = None
    amount: Optional[float] = None


class Invoice(BaseModel):
    """账单信息"""
    invoice_type: Optional[str] = None
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None
    seller_name: Optional[str] = None
    buyer_name: Optional[str] = None
    buyer_phone: Optional[str] = None
    buyer_address: Optional[str] = None
    total_amount: Optional[float] = None
    items: List[InvoiceItem] = []
    remarks: Optional[str] = None


class ScanResult(BaseModel):
    """扫描结果"""
    success: bool
    message: str
    data: Optional[dict] = None
    performance: Optional[dict] = None


def parse_single_order(order_block, llm_engine, is_bank_statement=False):
    """解析单个订单（用于并发）"""
    if is_bank_statement:
        parser = BankStatementParser()
        result = parser.parse(order_block.text)
    else:
        parser = FastBillParser(llm_engine)
        result = parser.parse(order_block.text)

    # 添加状态信息
    if result.success and result.invoice:
        if not result.invoice.remarks:
            result.invoice.remarks = f"订单状态: {order_block.status}"
        else:
            result.invoice.remarks += f" | 订单状态: {order_block.status}"

    return result, order_block.status


@app.get("/")
async def root():
    """根路径"""
    return {
        "name": "KAPI - 智能账单识别 API",
        "version": "2.0.0",
        "endpoints": {
            "scan": "/api/scan (POST)",
            "health": "/health (GET)",
            "docs": "/docs (Swagger UI)",
            "redoc": "/redoc (ReDoc)"
        }
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "ok", "service": "kapi"}


@app.post("/api/scan", response_model=ScanResult)
async def scan_bill(
    file: UploadFile = File(..., description="账单图片文件"),
    model: str = Query("qwen2.5:3b", description="LLM 模型名称"),
    fast_mode: bool = Query(False, description="快速模式（小模型+并发+快速OCR）"),
    concurrent: bool = Query(False, description="启用并发解析"),
    no_angle: bool = Query(False, description="关闭 OCR 角度检测"),
):
    """
    扫描账单接口

    支持的账单类型:
    - 餐饮订单（单个/列表）
    - 电商订单（单个/列表）
    - 银行流水（多条记录）
    - 增值税发票

    参数:
    - file: 上传的图片文件
    - model: LLM 模型（默认: qwen2.5:3b）
    - fast_mode: 快速模式（自动优化所有参数）
    - concurrent: 启用并发解析订单列表
    - no_angle: 关闭 OCR 角度检测（图片方向正确时）
    """

    start_time = time.time()
    times = {}
    temp_file = None

    try:
        # 快速模式自动配置
        if fast_mode:
            model = "qwen2.5:1.5b"
            no_angle = True
            concurrent = True

        # 保存上传文件到临时目录
        suffix = Path(file.filename).suffix
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            content = await file.read()
            tmp.write(content)
            temp_file = tmp.name

        logger.info(f"Processing file: {file.filename}, size: {len(content)} bytes")

        # OCR 提取
        t = time.time()
        use_angle_cls = not no_angle
        ocr = RapidOCREngine(use_angle_cls=use_angle_cls, print_verbose=False)
        ocr_result = ocr.extract_text(temp_file)
        times['ocr'] = time.time() - t

        if not ocr_result.success:
            raise HTTPException(status_code=400, detail=f"OCR 失败: {ocr_result.error_message}")

        logger.info(f"OCR completed: {len(ocr_result.lines)} lines, {ocr_result.avg_score:.1%} confidence")

        # 初始化 LLM
        t = time.time()
        llm = OllamaEngine(model_name=model, temperature=0.0, max_tokens=512)
        times['init'] = time.time() - t

        # 检测订单类型
        t = time.time()
        multi_parser = MultiOrderParser(llm)
        is_list, list_conf = multi_parser.is_order_list(ocr_result.text)
        times['detect'] = time.time() - t

        # 解析账单
        if is_list:
            # 订单列表处理
            t = time.time()
            order_blocks = multi_parser.split_orders(ocr_result.text)
            times['split'] = time.time() - t

            logger.info(f"Detected {len(order_blocks)} orders in list")

            # 检测是否是银行流水
            is_bank_statement = multi_parser._is_bank_statement_list(ocr_result.text)

            t = time.time()
            if concurrent and len(order_blocks) > 1:
                # 并发解析
                results = []
                stats = {
                    'total_orders': len(order_blocks),
                    'completed': 0,
                    'cancelled': 0,
                    'in_progress': 0,
                    'other': 0,
                }

                with ThreadPoolExecutor(max_workers=min(len(order_blocks), 4)) as executor:
                    futures = {
                        executor.submit(parse_single_order, block, llm, is_bank_statement): i
                        for i, block in enumerate(order_blocks)
                    }

                    temp_results = [None] * len(order_blocks)
                    for future in as_completed(futures):
                        idx = futures[future]
                        result, status = future.result()
                        temp_results[idx] = (result, status)

                    for result, status in temp_results:
                        results.append(result)
                        if status == '已完成':
                            stats['completed'] += 1
                        elif status == '已取消':
                            stats['cancelled'] += 1
                        elif status in ['进行中', '待支付', '待发货', '待收货']:
                            stats['in_progress'] += 1
                        else:
                            stats['other'] += 1
            else:
                # 串行解析
                results, stats = multi_parser.parse_order_list(ocr_result.text)

            times['parse'] = time.time() - t

            # 转换为 JSON
            invoices = []
            total_amount = 0
            for result in results:
                if result.success and result.invoice:
                    inv = result.invoice
                    invoices.append({
                        "invoice_type": inv.invoice_type,
                        "invoice_number": inv.invoice_number,
                        "invoice_date": inv.invoice_date,
                        "seller_name": inv.seller_name,
                        "buyer_name": inv.buyer_name,
                        "total_amount": inv.total_amount,
                        "items": [
                            {
                                "name": item.name,
                                "quantity": item.quantity,
                                "amount": item.amount
                            }
                            for item in (inv.items or [])
                        ],
                        "remarks": inv.remarks
                    })
                    if "已完成" in (inv.remarks or "") and inv.total_amount:
                        total_amount += inv.total_amount

            times['total'] = time.time() - start_time

            return ScanResult(
                success=True,
                message=f"成功识别 {len(invoices)} 个订单",
                data={
                    "type": "order_list",
                    "invoices": invoices,
                    "statistics": stats,
                    "total_amount": round(total_amount, 2),
                    "parse_mode": "concurrent" if concurrent and len(order_blocks) > 1 else "serial"
                },
                performance={
                    "ocr_time": round(times['ocr'], 2),
                    "parse_time": round(times['parse'], 2),
                    "total_time": round(times['total'], 2),
                    "model": model
                }
            )
        else:
            # 单个订单处理
            t = time.time()
            parser = SmartParser(llm)
            bill_type, conf, mode = parser.detect_type_only(ocr_result.text)
            times['detect_type'] = time.time() - t

            t = time.time()
            result = parser.parse(ocr_result.text)
            times['parse'] = time.time() - t

            if not result.success:
                raise HTTPException(status_code=400, detail=f"解析失败: {result.error_message}")

            times['total'] = time.time() - start_time

            inv = result.invoice
            return ScanResult(
                success=True,
                message="成功识别单个订单",
                data={
                    "type": "single_order",
                    "invoice": {
                        "invoice_type": inv.invoice_type,
                        "invoice_number": inv.invoice_number,
                        "invoice_date": inv.invoice_date,
                        "seller_name": inv.seller_name,
                        "buyer_name": inv.buyer_name,
                        "buyer_phone": inv.buyer_phone,
                        "buyer_address": inv.buyer_address,
                        "total_amount": inv.total_amount,
                        "items": [
                            {
                                "name": item.name,
                                "quantity": item.quantity,
                                "amount": item.amount
                            }
                            for item in (inv.items or [])
                        ],
                        "remarks": inv.remarks
                    },
                    "bill_type": bill_type,
                    "confidence": round(conf, 2)
                },
                performance={
                    "ocr_time": round(times['ocr'], 2),
                    "parse_time": round(times['parse'], 2),
                    "total_time": round(times['total'], 2),
                    "model": model
                }
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing request: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"处理失败: {str(e)}")

    finally:
        # 清理临时文件
        if temp_file and os.path.exists(temp_file):
            try:
                os.unlink(temp_file)
            except:
                pass


if __name__ == "__main__":
    import uvicorn

    print("🚀 启动 KAPI 智能账单识别服务...")
    print("📖 API 文档: http://localhost:8000/docs")
    print("🔍 ReDoc: http://localhost:8000/redoc")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
