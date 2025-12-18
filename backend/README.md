# KAPI HTTP Server

基于 FastAPI 的智能账单识别 HTTP 服务，单文件实现，简单高效。

## 🚀 快速开始

```bash
cd backend

# 安装依赖
pip3 install -r requirements.txt
pip3 install -r ../engine/requirements.txt

# 启动服务
./start.sh

# 或直接运行
python3 server.py
```

访问 API 文档：http://localhost:8080/docs

## 📡 API 接口

### 1. 健康检查

```bash
GET /health
```

### 2. 标准扫描

```bash
POST /scan

参数:
- file: 图片文件
- skip_items: 跳过商品明细 (default: false)
- clean_text: 清理文本 (default: false)
- format_text: 格式化文本 (default: false)
- concurrent: 并发处理 (default: false)
- use_angle_cls: 角度检测 (default: true)
- model: LLM 模型 (default: qwen2.5:3b)
```

### 3. 快速扫描

```bash
POST /scan/fast

参数:
- file: 图片文件
- concurrent: 并发处理 (default: true)
```

## 💡 使用示例

### cURL

```bash
# 标准扫描
curl -X POST "http://localhost:8080/scan" \
  -F "file=@test.jpg" \
  -F "skip_items=false"

# 快速扫描
curl -X POST "http://localhost:8080/scan/fast" \
  -F "file=@test.jpg"
```

### Python

```python
import requests

# 标准扫描
with open("test.jpg", "rb") as f:
    response = requests.post(
        "http://localhost:8080/scan",
        files={"file": f},
        data={"skip_items": False}
    )
    print(response.json())

# 快速扫描
with open("test.jpg", "rb") as f:
    response = requests.post(
        "http://localhost:8080/scan/fast",
        files={"file": f}
    )
    print(response.json())
```

## 📊 响应格式

### 单个订单

```json
{
  "success": true,
  "data": {
    "type": "single_order",
    "invoice": {
      "invoice_type": "Food Delivery",
      "seller_name": "麦当劳",
      "total_amount": 45.50,
      "items": [...]
    },
    "confidence": 0.95
  },
  "performance": {
    "ocr": 1.23,
    "detect_type": 0.45,
    "parse": 2.67,
    "total": 4.35
  }
}
```

### 订单列表

```json
{
  "success": true,
  "data": {
    "type": "order_list",
    "total_orders": 3,
    "stats": {
      "total_orders": 3,
      "completed": 2,
      "cancelled": 1,
      "in_progress": 0
    },
    "orders": [...]
  },
  "performance": {
    "ocr": 1.50,
    "detect_type": 0.50,
    "split": 0.80,
    "parse": 3.20,
    "total": 6.00
  }
}
```

## 🔧 项目结构

```
backend/
├── server.py          # 主服务文件（单文件实现）
├── requirements.txt   # Python 依赖
├── start.sh          # 启动脚本
└── README.md         # 本文档
```

## ⚙️ 配置

编辑 `server.py` 中的配置：

```python
DEFAULT_MODEL = "qwen2.5:3b"    # 默认模型
FAST_MODEL = "qwen2.5:1.5b"     # 快速模式模型
```

## 📝 特性

- ✅ 单文件实现，简单易懂
- ✅ 自动 API 文档（Swagger UI）
- ✅ 健康检查端点
- ✅ 支持单个订单和订单列表
- ✅ 标准模式和快速模式
- ✅ 并发处理支持
- ✅ 性能统计
- ✅ CORS 支持

## 📄 许可证

MIT License
