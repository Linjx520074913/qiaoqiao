#!/bin/bash

# KAPI Backend 启动脚本

echo "=========================================="
echo "  KAPI Backend - 启动服务"
echo "=========================================="
echo ""

# 进入backend目录
cd "$(dirname "$0")"

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

echo "✓ Python版本: $(python3 --version)"
echo ""

# 启动服务
echo "启动 FastAPI 服务..."
echo "访问地址:"
echo "  - API文档: http://localhost:8080/docs"
echo "  - ReDoc文档: http://localhost:8080/redoc"
echo "  - 健康检查: http://localhost:8080/health"
echo ""

cd app && python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload
