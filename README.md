# KAPI - 智能账单识别系统

一个基于AI的账单识别系统，支持单个订单和订单列表的智能识别。

## 📁 项目结构

```
kapi/
├── engine/          # 🔧 识别引擎（核心算法）
├── backend/         # 🌐 FastAPI 后端服务
├── app/             # 📱 Flutter 移动应用
└── README.md        # 📖 项目文档（本文件）
```

## 🚀 快速开始

### 1. 识别引擎（Engine）

核心识别引擎，支持命令行使用。

```bash
cd engine

# 安装依赖
pip3 install -r requirements.txt

# 识别单个账单
python3 scan_bill.py /path/to/image.jpg --no-angle --no-items

# 识别订单列表
python3 scan_bill.py /path/to/list.jpg --no-angle --no-items --concurrent
```

### 2. FastAPI 后端（Backend）

RESTful API 服务，提供HTTP接口。

```bash
cd backend

# 安装依赖
pip3 install -r requirements.txt
pip3 install -r ../engine/requirements.txt

# 启动服务
./start.sh

# 访问API文档
# http://localhost:8080/docs
```

**详细文档**: [backend/README.md](backend/README.md)

### 3. Flutter 应用（App）

移动端应用（开发中）。

```bash
cd app

# 创建Flutter项目
flutter create .

# 运行应用
flutter run
```

**详细文档**: [app/README.md](app/README.md)

## ✨ 核心功能

### 识别引擎特性
- ✅ **OCR文本提取**: 基于RapidOCR
- ✅ **智能类型检测**: 自动识别账单类型（外卖、电商、发票等）
- ✅ **多订单处理**: 支持订单列表识别和分离
- ✅ **银行流水识别**: 智能解析银行短信流水
- ✅ **性能优化**: 多种优化模式（--clean, --format, --no-items）
- ✅ **时间自动填充**: 无时间信息时使用系统时间

### API 特性
- ✅ **RESTful接口**: 标准HTTP API
- ✅ **自动文档**: Swagger UI / ReDoc
- ✅ **文件上传**: 支持多种图片格式
- ✅ **并发处理**: 订单列表并发识别
- ✅ **性能统计**: 详细的时间统计
- ✅ **健康检查**: 服务状态监控

## 📊 性能指标

| 场景 | 时间 | 说明 |
|------|------|------|
| 单个订单（完整） | ~5-6s | 包含商品明细 |
| 单个订单（快速） | ~2-3s | 仅关键信息（--no-items） |
| 订单列表（3个） | ~4-5s | 并发模式（--concurrent） |
| 银行流水 | ~1-2s | 正则解析，极快 |

## 🛠️ 技术栈

### 引擎
- **OCR**: RapidOCR
- **LLM**: Ollama / vLLM (Qwen2.5-3B)
- **语言**: Python 3.8+

### 后端
- **框架**: FastAPI
- **服务器**: Uvicorn
- **数据验证**: Pydantic

### 应用
- **框架**: Flutter
- **语言**: Dart

## 📖 使用示例

### Engine CLI
```bash
# 快速识别（仅总金额）
python3 scan_bill.py order.jpg --no-angle --no-items

# 完整识别（包含明细）
python3 scan_bill.py order.jpg --no-angle

# 订单列表并发处理
python3 scan_bill.py list.jpg --no-angle --no-items --concurrent
```

### API调用
```bash
# 使用 curl
curl -X POST "http://localhost:8080/api/v1/bills/scan" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.jpg" \
  -F "skip_items=true"

# 使用 Python requests
import requests

with open('test.jpg', 'rb') as f:
    response = requests.post(
        'http://localhost:8080/api/v1/bills/scan',
        files={'file': f},
        data={'skip_items': True}
    )
    print(response.json())
```

## 🔧 配置说明

### LLM模型配置

**Ollama** (推荐)
```bash
# 安装模型
ollama pull qwen2.5:3b

# 启动服务（自动）
# 识别引擎会自动连接 Ollama
```

**vLLM** (高性能)
```bash
cd engine/scripts
./start_vllm.sh
```

## 📦 依赖安装

### 完整安装
```bash
# 引擎依赖
cd engine && pip3 install -r requirements.txt

# 后端依赖
cd ../backend && pip3 install -r requirements.txt

# 应用依赖
cd ../app && flutter pub get
```

## 📝 更新日志

### v1.0.0 (2025-12-17)
- ✅ 完成识别引擎核心功能
- ✅ 实现 FastAPI 后端服务
- ✅ 添加时间自动填充功能
- ✅ 优化性能（--no-items 模式）
- ✅ 清理冗余文件，重组项目结构

## 📄 许可证

MIT License

## 🔗 相关链接

- **API文档**: http://localhost:8080/docs
- **Backend README**: [backend/README.md](backend/README.md)
- **Engine README**: [engine/README.md](engine/README.md)
- **App README**: [app/README.md](app/README.md)

---

⭐ 如果这个项目对你有帮助，请给个 Star！
