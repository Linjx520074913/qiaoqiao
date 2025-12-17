# KAPI Backend

账单识别系统 FastAPI 后端服务

## 功能特性

- ✅ RESTful API 接口
- ✅ 自动生成 API 文档（Swagger/ReDoc）
- ✅ 图片上传处理
- ✅ 账单识别（单个/列表）
- ✅ 性能统计
- ✅ 健康检查
- ✅ CORS 支持

## 安装依赖

```bash
# 安装后端依赖
pip3 install -r requirements.txt

# 安装引擎依赖
pip3 install -r ../engine/requirements.txt
```

## 启动服务

### 方式1：使用启动脚本
```bash
./start.sh
```

### 方式2：直接运行
```bash
cd app
python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

## 访问地址

- **API 文档**: http://localhost:8080/docs
- **ReDoc 文档**: http://localhost:8080/redoc
- **健康检查**: http://localhost:8080/health

## API 端点

### POST /api/v1/bills/scan
扫描账单图片

**请求参数:**
- `file`: 图片文件（必需）
- `use_angle_cls`: 是否使用角度分类（默认：false）
- `clean_text`: 是否清理文本（默认：false）
- `format_text`: 是否格式化文本（默认：false）
- `skip_items`: 是否跳过商品明细（默认：false）
- `concurrent`: 是否并发处理（默认：false）

**响应示例:**
```json
{
  "success": true,
  "message": "账单识别成功",
  "invoice": {
    "invoice_type": "Food Delivery",
    "seller_name": "麦当劳深圳南山智谷餐厅",
    "invoice_date": "2025-12-17 17:41:17",
    "total_amount": 34.60,
    "items": [...]
  },
  "is_list": false,
  "performance": {
    "ocr": 1.2,
    "parse": 1.5,
    "total": 2.8
  }
}
```

### GET /api/v1/bills/health
健康检查

## 配置

编辑 `app/core/config.py` 或创建 `.env` 文件：

```env
# LLM配置
LLM_MODEL=qwen2.5:3b

# 服务器配置
HOST=0.0.0.0
PORT=8080

# 上传限制
MAX_UPLOAD_SIZE=10485760  # 10MB
```

## 项目结构

```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   └── scan.py      # 扫描端点
│   │       └── __init__.py
│   ├── core/
│   │   └── config.py            # 配置文件
│   ├── schemas/
│   │   └── invoice.py           # 数据模型
│   ├── models/                  # 数据库模型（预留）
│   └── main.py                  # 主应用
├── requirements.txt             # 依赖
├── start.sh                     # 启动脚本
└── README.md                    # 文档
```

## 开发说明

### 添加新端点

1. 在 `app/api/v1/endpoints/` 创建新文件
2. 在 `app/api/v1/__init__.py` 注册路由
3. 在 `app/schemas/` 添加对应的数据模型

### 测试API

使用 curl 测试：
```bash
curl -X POST "http://localhost:8080/api/v1/bills/scan" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.jpg" \
  -F "skip_items=true"
```

或访问 Swagger UI：http://localhost:8080/docs

## 依赖说明

- **FastAPI**: Web 框架
- **Uvicorn**: ASGI 服务器
- **Pydantic**: 数据验证
- **Pillow**: 图片处理

## 注意事项

1. 首次启动需要下载 LLM 模型（qwen2.5:3b）
2. 确保 Ollama 服务已运行（或使用 vLLM）
3. 生产环境建议：
   - 关闭 `reload` 模式
   - 配置具体的 CORS 域名
   - 使用 Nginx 反向代理
   - 增加请求限流
