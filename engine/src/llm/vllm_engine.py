"""
vLLM 推理引擎封装
支持 OpenAI 兼容 API 和直接推理
"""

import json
import logging
from typing import Optional, Dict, Any
from openai import OpenAI

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class VLLMEngine:
    """vLLM 推理引擎封装类"""

    def __init__(
        self,
        model_name: str = "mistralai/Mistral-7B-Instruct-v0.2",
        api_base: str = "http://localhost:8000/v1",
        api_key: str = "EMPTY",
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ):
        """
        初始化 vLLM 引擎

        Args:
            model_name: 模型名称
            api_base: vLLM API 地址
            api_key: API 密钥（本地部署时通常为 EMPTY）
            temperature: 采样温度
            max_tokens: 最大生成 token 数
        """
        self.model_name = model_name
        self.temperature = temperature
        self.max_tokens = max_tokens

        # 初始化 OpenAI 客户端（vLLM 兼容 OpenAI API）
        self.client = OpenAI(
            api_key=api_key,
            base_url=api_base,
        )

        logger.info(f"VLLMEngine initialized with model: {model_name}")

    def generate(
        self,
        prompt: str,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        json_mode: bool = False,
    ) -> str:
        """
        生成文本

        Args:
            prompt: 输入提示词
            temperature: 采样温度（可选，覆盖默认值）
            max_tokens: 最大生成 token 数（可选，覆盖默认值）
            json_mode: 是否启用 JSON 模式

        Returns:
            生成的文本
        """
        try:
            temperature = temperature if temperature is not None else self.temperature
            max_tokens = max_tokens if max_tokens is not None else self.max_tokens

            # 构建请求参数
            kwargs = {
                "model": self.model_name,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": temperature,
                "max_tokens": max_tokens,
            }

            # 如果启用 JSON 模式
            if json_mode:
                kwargs["response_format"] = {"type": "json_object"}

            # 调用 API
            response = self.client.chat.completions.create(**kwargs)

            # 提取生成的文本
            generated_text = response.choices[0].message.content

            logger.info(f"Generated text length: {len(generated_text)}")
            return generated_text

        except Exception as e:
            logger.error(f"Error during generation: {e}")
            raise

    def generate_json(
        self,
        prompt: str,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        生成 JSON 格式输出

        Args:
            prompt: 输入提示词（需要明确要求返回 JSON）
            temperature: 采样温度
            max_tokens: 最大生成 token 数

        Returns:
            解析后的 JSON 字典
        """
        # 在提示词中明确要求 JSON 格式
        if "json" not in prompt.lower():
            prompt = f"{prompt}\n\nPlease respond with a valid JSON object only."

        # 生成文本
        text = self.generate(
            prompt=prompt,
            temperature=temperature,
            max_tokens=max_tokens,
            json_mode=True,
        )

        # 解析 JSON
        try:
            # 尝试直接解析
            return json.loads(text)
        except json.JSONDecodeError:
            # 如果失败，尝试提取 JSON 部分
            logger.warning("Failed to parse JSON directly, trying to extract...")
            return self._extract_json(text)

    def _extract_json(self, text: str) -> Dict[str, Any]:
        """从文本中提取 JSON"""
        # 查找 JSON 代码块
        if "```json" in text:
            start = text.find("```json") + 7
            end = text.find("```", start)
            json_text = text[start:end].strip()
        elif "{" in text and "}" in text:
            start = text.find("{")
            end = text.rfind("}") + 1
            json_text = text[start:end]
        else:
            raise ValueError("No valid JSON found in response")

        return json.loads(json_text)

    def test_connection(self) -> bool:
        """测试与 vLLM 服务的连接"""
        try:
            response = self.generate("Hello", max_tokens=10)
            logger.info("Connection test successful")
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False
