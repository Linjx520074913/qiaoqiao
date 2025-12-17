#!/bin/bash

# KAPI - vLLM 服务启动脚本

echo "=========================================="
echo "  KAPI - 启动 vLLM 服务"
echo "=========================================="
echo ""

# 默认配置
MODEL=${MODEL:-"mistralai/Mistral-7B-Instruct-v0.2"}
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-8000}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.9}

echo "配置信息:"
echo "  模型: $MODEL"
echo "  主机: $HOST"
echo "  端口: $PORT"
echo "  GPU 内存利用率: $GPU_MEMORY_UTILIZATION"
echo ""

# 检查 vLLM 是否安装
if ! python -c "import vllm" 2>/dev/null; then
    echo "❌ vLLM 未安装"
    echo "请运行: pip install vllm"
    exit 1
fi

# 国内用户加速下载（可选）
# export HF_ENDPOINT=https://hf-mirror.com

echo "启动 vLLM 服务..."
echo ""

# 启动 vLLM OpenAI 兼容服务器
python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL" \
    --host "$HOST" \
    --port "$PORT" \
    --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
    --dtype auto \
    --max-model-len 4096

# 如果需要使用量化模型以节省显存，取消下面的注释:
# --quantization awq
