#!/bin/bash

# KAPI HTTP Server 启动脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  KAPI HTTP Server${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Python
echo -e "\n${YELLOW}Checking Python...${NC}"
python3 --version

# 检查 Ollama
echo -e "\n${YELLOW}Checking Ollama...${NC}"
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}Ollama: $(ollama --version)${NC}"

    # 检查模型
    if ! ollama list | grep -q "qwen2.5:3b"; then
        echo -e "${YELLOW}Pulling model: qwen2.5:3b${NC}"
        ollama pull qwen2.5:3b
    fi

    if ! ollama list | grep -q "qwen2.5:1.5b"; then
        echo -e "${YELLOW}Pulling model: qwen2.5:1.5b${NC}"
        ollama pull qwen2.5:1.5b
    fi
else
    echo -e "${RED}Warning: Ollama not found${NC}"
fi

# 安装依赖
echo -e "\n${YELLOW}Checking dependencies...${NC}"
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}Installing backend dependencies...${NC}"
    pip3 install -r requirements.txt
fi

if ! python3 -c "import rapidocr_onnxruntime" 2>/dev/null; then
    echo -e "${YELLOW}Installing engine dependencies...${NC}"
    pip3 install -r ../engine/requirements.txt
fi

echo -e "${GREEN}Dependencies OK${NC}"

# 启动服务
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Starting Server${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}URL: http://localhost:8080${NC}"
echo -e "${YELLOW}Docs: http://localhost:8080/docs${NC}"
echo -e "${GREEN}========================================${NC}\n"

python3 server.py
