# KAPI API 文档

智能账单识别 REST API 服务

## 快速开始

### 1. 启动服务

```bash
python3 api.py
```

服务将在 `http://localhost:8000` 启动

### 2. 查看文档

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### 3. 调用 API

```bash
# 快速模式
curl -X POST "http://localhost:8000/api/scan?fast_mode=true" \
  -F "file=@bill.jpg"

# 标准模式
curl -X POST "http://localhost:8000/api/scan" \
  -F "file=@bill.jpg"

# 自定义模型
curl -X POST "http://localhost:8000/api/scan?model=qwen2.5:7b" \
  -F "file=@bill.jpg"
```

---

## API 接口

### 1. 根路径

**GET** `/`

返回 API 基本信息

**响应示例:**
```json
{
  "name": "KAPI - 智能账单识别 API",
  "version": "2.0.0",
  "endpoints": {
    "scan": "/api/scan (POST)",
    "health": "/health (GET)"
  }
}
```

---

### 2. 健康检查

**GET** `/health`

检查服务状态

**响应示例:**
```json
{
  "status": "ok",
  "service": "kapi"
}
```

---

### 3. 扫描账单 ⭐

**POST** `/api/scan`

上传图片识别账单信息

#### 请求参数

**Query Parameters:**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `model` | string | qwen2.5:3b | LLM 模型名称 |
| `fast_mode` | boolean | false | 快速模式（小模型+并发+快速OCR） |
| `concurrent` | boolean | false | 启用并发解析订单列表 |
| `no_angle` | boolean | false | 关闭 OCR 角度检测 |

**Body:**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | file | ✅ | 账单图片文件 |

#### 响应数据

##### 订单列表响应

```json
{
  "success": true,
  "message": "成功识别 6 个订单",
  "data": {
    "type": "order_list",
    "invoices": [
      {
        "invoice_type": "Bank Statement",
        "invoice_number": "中国银行-06538",
        "invoice_date": "2025-12-01",
        "seller_name": "中国银行",
        "buyer_name": "账户 06538",
        "total_amount": 19518.95,
        "items": [
          {
            "name": "收入",
            "quantity": 1.0,
            "amount": 19518.95
          }
        ],
        "remarks": "余额: ¥19745.37 | 订单状态: 已完成"
      }
    ],
    "statistics": {
      "total_orders": 6,
      "completed": 6,
      "cancelled": 0,
      "in_progress": 0,
      "other": 0
    },
    "total_amount": 39240.76,
    "parse_mode": "concurrent"
  },
  "performance": {
    "ocr_time": 1.37,
    "parse_time": 0.0,
    "total_time": 1.38,
    "model": "qwen2.5:1.5b"
  }
}
```

##### 单个订单响应

```json
{
  "success": true,
  "message": "成功识别单个订单",
  "data": {
    "type": "single_order",
    "invoice": {
      "invoice_type": "Food Delivery",
      "seller_name": "麦当劳",
      "total_amount": 34.60,
      "items": [
        {
          "name": "原味板烧鸡腿炒双蛋堡",
          "quantity": 2,
          "amount": 24.60
        }
      ]
    },
    "bill_type": "Food Delivery",
    "confidence": 0.85
  },
  "performance": {
    "ocr_time": 1.20,
    "parse_time": 3.45,
    "total_time": 4.72,
    "model": "qwen2.5:3b"
  }
}
```

---

## Python 客户端示例

```python
import requests

def scan_bill(image_path: str):
    """调用 KAPI API 识别账单"""

    url = "http://localhost:8000/api/scan"
    params = {"fast_mode": True}

    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(url, files=files, params=params)

    if response.status_code == 200:
        result = response.json()
        print(f"✅ {result['message']}")
        print(f"💰 总金额: ¥{result['data'].get('total_amount', 0)}")
        return result
    else:
        print(f"❌ 失败: {response.status_code}")
        return None

# 使用示例
result = scan_bill("bill.jpg")
```

---

## JavaScript 客户端示例

```javascript
async function scanBill(file) {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch('http://localhost:8000/api/scan?fast_mode=true', {
    method: 'POST',
    body: formData
  });

  if (response.ok) {
    const result = await response.json();
    console.log('✅', result.message);
    console.log('💰 总金额:', result.data.total_amount);
    return result;
  } else {
    console.error('❌ 识别失败');
    return null;
  }
}

// 使用示例 (HTML)
// <input type="file" id="billFile" accept="image/*">
document.getElementById('billFile').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  const result = await scanBill(file);
});
```

---

## 性能优化

### 快速模式 (推荐)

```bash
curl -X POST "http://localhost:8000/api/scan?fast_mode=true" \
  -F "file=@bill.jpg"
```

自动启用:
- ✅ 小模型 (qwen2.5:1.5b)
- ✅ 并发解析
- ✅ 快速 OCR

**效果**: 速度提升 35% - 60%

### 性能对比

| 模式 | 订单列表 (3个) | 银行流水 (6条) |
|------|----------------|----------------|
| **标准** | ~13s | ~1.4s |
| **快速** | **~8s** | **~1.4s** |
| **提升** | ⚡ 38%↓ | ⚡ 瞬间 |

---

## 支持的账单类型

- ✅ 餐饮订单（美团、饿了么、麦当劳等）
- ✅ 电商订单（淘宝、京东、拼多多等）
- ✅ 银行流水（中国银行、建设银行等）
- ✅ 增值税发票
- ✅ 普通发票
- ✅ 订单列表（自动分离多个订单）

---

## 错误处理

### 400 Bad Request

OCR 或解析失败

```json
{
  "detail": "OCR 失败: 无法识别文本"
}
```

### 500 Internal Server Error

服务器内部错误

```json
{
  "detail": "处理失败: 模型加载失败"
}
```

---

## 部署建议

### 开发环境

```bash
python3 api.py
```

### 生产环境

```bash
# 使用 gunicorn + uvicorn
gunicorn api:app -w 4 -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --timeout 120

# 或使用 Docker
docker build -t kapi .
docker run -p 8000:8000 kapi
```

### 性能调优

1. **并发工作进程**: 根据 CPU 核心数调整 `-w` 参数
2. **超时设置**: 根据实际处理时间调整 `--timeout`
3. **缓存**: 考虑添加 Redis 缓存 OCR 结果
4. **负载均衡**: 使用 Nginx 做反向代理

---

## 许可证

MIT License

---

## 联系方式

- 项目地址: https://github.com/your-repo/kapi
- 问题反馈: https://github.com/your-repo/kapi/issues
