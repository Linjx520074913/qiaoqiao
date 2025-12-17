"""
API v1 路由配置
"""
from fastapi import APIRouter
from app.api.v1.endpoints import scan

api_router = APIRouter()

# 注册端点
api_router.include_router(scan.router, prefix="/bills", tags=["bills"])
