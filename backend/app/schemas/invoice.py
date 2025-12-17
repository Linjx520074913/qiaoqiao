"""
账单数据模型
"""
from typing import Optional, List
from pydantic import BaseModel, Field


class InvoiceItem(BaseModel):
    """账单明细项"""
    name: str = Field(description="商品/服务名称")
    quantity: Optional[float] = Field(default=None, description="数量")
    unit_price: Optional[float] = Field(default=None, description="单价")
    amount: Optional[float] = Field(default=None, description="金额")
    description: Optional[str] = Field(default=None, description="备注说明")


class Invoice(BaseModel):
    """账单信息"""
    invoice_type: Optional[str] = Field(default=None, description="账单类型")
    invoice_number: Optional[str] = Field(default=None, description="账单号/订单号")
    invoice_date: Optional[str] = Field(default=None, description="账单日期")

    seller_name: Optional[str] = Field(default=None, description="商家名称")
    buyer_name: Optional[str] = Field(default=None, description="客户名称")
    buyer_phone: Optional[str] = Field(default=None, description="客户电话")

    total_amount: Optional[float] = Field(default=None, description="总金额")
    items: List[InvoiceItem] = Field(default_factory=list, description="账单明细")

    remarks: Optional[str] = Field(default=None, description="备注")


class ScanRequest(BaseModel):
    """扫描请求"""
    use_angle_cls: bool = Field(default=False, description="是否使用角度分类")
    clean_text: bool = Field(default=False, description="是否清理文本")
    format_text: bool = Field(default=False, description="是否格式化文本")
    skip_items: bool = Field(default=False, description="是否跳过商品明细")
    concurrent: bool = Field(default=False, description="是否并发处理订单列表")


class ScanResponse(BaseModel):
    """扫描响应"""
    success: bool = Field(description="是否成功")
    message: Optional[str] = Field(default=None, description="消息")
    invoice: Optional[Invoice] = Field(default=None, description="账单信息")
    invoices: Optional[List[Invoice]] = Field(default=None, description="账单列表（订单列表）")
    is_list: bool = Field(default=False, description="是否是订单列表")
    stats: Optional[dict] = Field(default=None, description="统计信息")
    performance: Optional[dict] = Field(default=None, description="性能统计")


class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str
    version: str
    engine_status: str
