# KAPI - 智能账单识别引擎

基于本地 LLM（Mistral + vLLM）的智能账单信息提取系统，支持将 OCR 识别的文本转换为结构化 JSON 数据。

## 特性

- **本地部署**: 使用 vLLM 高性能推理引擎，支持本地模型部署
- **通用识别**: 支持多种账单类型（发票、收据、订单、流水等）
- **结构化输出**: 自动提取账单信息并输出标准 JSON 格式
- **Few-shot 学习**: 内置示例，提升识别准确率
- **JSON 验证**: 自动验证输出格式，确保数据质量
- **批量处理**: 支持批量账单解析

## 系统架构

```
OCR 文本 → LLM 推理引擎 → 账单解析器 → JSON 输出
            (vLLM + Mistral)  (提示词工程)
```

## 安装

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd kapi
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 启动 vLLM 服务

```bash
# 下载并启动 Mistral 模型
python -m vllm.entrypoints.openai.api_server \
    --model mistralai/Mistral-7B-Instruct-v0.2 \
    --host 0.0.0.0 \
    --port 8000
```

如果是首次运行，vLLM 会自动从 HuggingFace 下载模型。

**国内用户加速下载:**
```bash
export HF_ENDPOINT=https://hf-mirror.com
```

## 快速开始

### 基本使用

```python
from src.llm import VLLMEngine
from src.parser import BillParser

# 1. 初始化引擎
llm_engine = VLLMEngine(
    model_name="mistralai/Mistral-7B-Instruct-v0.2",
    api_base="http://localhost:8000/v1"
)

# 2. 创建解析器
parser = BillParser(llm_engine, use_few_shot=True)

# 3. 解析 OCR 文本
ocr_text = """
发票号：12345678
日期：2024-01-15
商品：笔记本 x2 单价：1500 金额：3000
总计：3000元
"""

result = parser.parse(ocr_text)

# 4. 获取结果
if result.success:
    print(f"置信度: {result.confidence:.2%}")
    print(parser.to_json(result, indent=2))
```

### 运行示例

```bash
# 查看使用示例
python examples/demo.py

# 运行测试
python tests/test_parser.py
```

## 项目结构

```
kapi/
├── config/
│   └── config.yaml          # 配置文件
├── src/
│   ├── models/
│   │   └── invoice.py       # 账单数据模型（Pydantic）
│   ├── llm/
│   │   └── vllm_engine.py   # vLLM 推理引擎封装
│   ├── parser/
│   │   └── bill_parser.py   # 账单解析核心逻辑
│   └── prompts/
│       └── templates.py     # 提示词模板 & Few-shot 示例
├── tests/
│   ├── test_parser.py       # 测试脚本
│   └── sample_bills/        # 示例账单
├── examples/
│   └── demo.py              # 使用示例
└── requirements.txt
```

## 配置

编辑 `config/config.yaml`:

```yaml
vllm:
  model_name: "mistralai/Mistral-7B-Instruct-v0.2"
  api_base: "http://localhost:8000/v1"
  temperature: 0.1
  max_tokens: 2048

parser:
  use_few_shot: true        # 是否使用 few-shot 示例
  validate_output: true     # 是否验证 JSON 输出
```

## 支持的账单字段

### 基本信息
- `invoice_type`: 账单类型
- `invoice_number`: 账单号/发票号
- `invoice_date`: 日期

### 交易方信息
- `seller_name`: 销售方名称
- `seller_tax_id`: 销售方税号
- `buyer_name`: 购买方名称
- `buyer_tax_id`: 购买方税号

### 金额信息
- `subtotal`: 小计
- `tax_amount`: 税额
- `total_amount`: 总金额

### 明细列表
- `items`: 商品/服务列表
  - `name`: 名称
  - `quantity`: 数量
  - `unit_price`: 单价
  - `amount`: 金额

### 其他
- `payment_method`: 支付方式
- `remarks`: 备注

## 模型选择

支持多种开源模型（需修改配置）:

- **Mistral** (推荐): 速度快，效果好
- **LLaMA 3**: 综合能力强
- **Qwen (通义千问)**: 中文优化
- **GLM (ChatGLM)**: 中文支持

## 性能优化

### 1. 使用更小的模型
```python
# 使用 7B 模型代替 13B/70B
model_name = "mistralai/Mistral-7B-Instruct-v0.2"
```

### 2. 关闭 Few-shot 示例
```python
parser = BillParser(llm_engine, use_few_shot=False)
```

### 3. 量化模型
```bash
# 使用 AWQ 4-bit 量化
--quantization awq
```

### 4. 调整批处理大小
```bash
# vLLM 启动时增加并发
--max-num-seqs 256
```

## 常见问题

### 1. vLLM 服务连接失败

确保 vLLM 服务已启动：
```bash
curl http://localhost:8000/v1/models
```

### 2. 模型下载慢

使用国内镜像：
```bash
export HF_ENDPOINT=https://hf-mirror.com
```

### 3. JSON 解析错误

启用验证并检查输出：
```python
parser = BillParser(llm_engine, validate_output=True)
```

### 4. 识别准确率低

- 启用 few-shot: `use_few_shot=True`
- 降低温度: `temperature=0.0`
- 使用更大的模型

## 扩展

### 添加自定义 Few-shot 示例

编辑 `src/prompts/templates.py`:

```python
FEW_SHOT_EXAMPLES = """
示例1:
输入文本：
你的示例文本...

输出JSON：
{
  "invoice_type": "...",
  ...
}
"""
```

### 支持其他模型

修改 `VLLMEngine` 初始化参数：

```python
llm_engine = VLLMEngine(
    model_name="meta-llama/Llama-3-8B-Instruct",  # 其他模型
    api_base="http://localhost:8000/v1"
)
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request!

## 联系方式

如有问题，请提交 Issue 或联系维护者。
