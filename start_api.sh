#!/bin/bash
# KAPI API 服务启动脚本

PORT=${1:-8000}

echo "🚀 KAPI 智能账单识别服务"
echo "===================================="

# 检查端口是否被占用
if lsof -ti:$PORT > /dev/null 2>&1; then
    echo "⚠️  端口 $PORT 已被占用"
    echo ""
    read -p "是否停止旧服务并重启? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 停止旧服务..."
        lsof -ti:$PORT | xargs kill -9 2>/dev/null
        sleep 1
    else
        echo "❌ 取消启动"
        exit 1
    fi
fi

echo ""
echo "✅ 启动服务在端口 $PORT"
echo "📖 API 文档: http://localhost:$PORT/docs"
echo "🔍 ReDoc: http://localhost:$PORT/redoc"
echo "🔗 健康检查: http://localhost:$PORT/health"
echo ""
echo "按 Ctrl+C 停止服务"
echo "===================================="
echo ""

# 启动服务
python3 api.py
