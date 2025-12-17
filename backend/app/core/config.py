"""
配置文件
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """应用配置"""

    # 应用信息
    APP_NAME: str = "KAPI Backend"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = "账单识别系统 API 服务"

    # API配置
    API_V1_PREFIX: str = "/api/v1"

    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8080

    # CORS配置
    CORS_ORIGINS: list = ["*"]  # 生产环境请限制具体域名

    # LLM配置
    LLM_MODEL: str = "qwen2.5:3b"
    LLM_BASE_URL: Optional[str] = None  # Ollama服务地址（如有）

    # 上传配置
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: set = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}

    # 引擎路径
    ENGINE_PATH: str = "../engine"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
