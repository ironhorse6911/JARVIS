"""Configuration management for JARVIS API"""
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    """Application settings from environment variables"""
    
    # API
    debug: bool = False
    log_level: str = "INFO"
    api_key_header: str = "X-API-Key"
    
    # Database
    database_url: str = "postgresql://jarvis:jarvis-secure-dev@localhost:5432/jarvis"
    db_echo: bool = False
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    cache_ttl: int = 3600
    
    # Ollama
    ollama_host: str = "http://localhost:11434"
    ollama_timeout: int = 300
    default_model: str = "jarvis"
    
    # Security
    secret_key: str = "dev-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440
    
    # Features
    enable_gpu_acceleration: bool = True
    max_concurrent_scans: int = 5
    max_model_size_mb: int = 10000
    
    # Multi-tenancy
    default_tenant: str = "default"
    enable_multi_tenant: bool = True
    
    # Cors
    cors_origins: str = "*"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
