#!/bin/bash
# KAPI API 服务停止脚本

PORT=${1:-8000}

echo "🛑 停止 KAPI 服务 (端口 $PORT)"

if lsof -ti:$PORT > /dev/null 2>&1; then
    lsof -ti:$PORT | xargs kill -9 2>/dev/null
    echo "✅ 服务已停止"
else
    echo "⚠️  没有服务运行在端口 $PORT"
fi
