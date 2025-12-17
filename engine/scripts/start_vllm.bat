@echo off
REM KAPI - vLLM 服务启动脚本 (Windows)

echo ==========================================
echo   KAPI - 启动 vLLM 服务
echo ==========================================
echo.

REM 默认配置
if "%MODEL%"=="" set MODEL=mistralai/Mistral-7B-Instruct-v0.2
if "%HOST%"=="" set HOST=0.0.0.0
if "%PORT%"=="" set PORT=8000
if "%GPU_MEMORY_UTILIZATION%"=="" set GPU_MEMORY_UTILIZATION=0.9

echo 配置信息:
echo   模型: %MODEL%
echo   主机: %HOST%
echo   端口: %PORT%
echo   GPU 内存利用率: %GPU_MEMORY_UTILIZATION%
echo.

REM 国内用户加速下载（可选）
REM set HF_ENDPOINT=https://hf-mirror.com

echo 启动 vLLM 服务...
echo.

python -m vllm.entrypoints.openai.api_server ^
    --model %MODEL% ^
    --host %HOST% ^
    --port %PORT% ^
    --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% ^
    --dtype auto ^
    --max-model-len 4096

pause
