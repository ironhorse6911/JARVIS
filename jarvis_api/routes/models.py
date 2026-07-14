"""AI model management endpoints"""
from fastapi import APIRouter, Request, Depends
from pydantic import BaseModel
from typing import List
from datetime import datetime
import structlog
import subprocess
import httpx

from jarvis_api.config import Settings
from jarvis_api.cache import get_cache

logger = structlog.get_logger(__name__)
router = APIRouter()
settings = Settings()

class ModelCreate(BaseModel):
    model_name: str
    persona: str = "jarvis"
    base_model: str = "ministral-3"
    temperature: float = 0.7
    specialty: str = "general"

class ModelResponse(BaseModel):
    model_id: str
    model_name: str
    status: str
    created_at: datetime

class ModelInfo(BaseModel):
    name: str
    size_gb: float
    created: str

@router.get("/list", response_model=List[ModelInfo])
async def list_models(request: Request):
    """List available Ollama models"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.ollama_host}/api/tags",
                timeout=10
            )
            data = response.json()
            models = [
                ModelInfo(
                    name=m['name'],
                    size_gb=m['size'] / (1024**3),
                    created=m.get('modified_at', 'unknown')
                )
                for m in data.get('models', [])
            ]
            return models
    except Exception as exc:
        logger.error("list_models_failed", error=str(exc))
        return []

@router.post("/create", response_model=ModelResponse)
async def create_model(
    request: Request,
    model: ModelCreate,
    cache = Depends(get_cache)
):
    """Create new AI model"""
    tenant_id = request.state.tenant_id
    model_id = f"{tenant_id}-{model.model_name}"
    
    logger.info("model_creation_started", tenant_id=tenant_id, model_name=model.model_name)
    
    try:
        # Execute create-model.sh
        result = subprocess.run([
            "bash", "create-model.sh",
            model.model_name,
            "-p", model.persona,
            "-b", model.base_model,
            "-t", str(model.temperature),
            "-s", model.specialty
        ], capture_output=True, text=True, timeout=300)
        
        if result.returncode != 0:
            raise Exception(f"Model creation failed: {result.stderr}")
        
        # Cache model metadata
        await cache.set(f"model:{model_id}", {
            "name": model.model_name,
            "tenant_id": tenant_id,
            "persona": model.persona,
            "created_at": datetime.utcnow().isoformat()
        }, ttl=86400*30)
        
        return ModelResponse(
            model_id=model_id,
            model_name=model.model_name,
            status="created",
            created_at=datetime.utcnow()
        )
    except Exception as exc:
        logger.error("model_creation_failed", tenant_id=tenant_id, error=str(exc))
        raise

@router.post("/invoke/{model_name}")
async def invoke_model(
    request: Request,
    model_name: str,
    prompt: str,
    cache = Depends(get_cache)
):
    """Run inference with AI model"""
    tenant_id = request.state.tenant_id
    
    # Check cache first
    cache_key = f"inference:{tenant_id}:{model_name}:{hash(prompt)}"
    cached = await cache.get(cache_key)
    if cached:
        return {"response": cached, "from_cache": True}
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.ollama_host}/api/generate",
                json={
                    "model": model_name,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=settings.ollama_timeout
            )
            result = response.json()
            
            # Cache response
            await cache.set(cache_key, result.get('response', ''), ttl=3600)
            
            logger.info("model_inference_completed", tenant_id=tenant_id, model_name=model_name)
            
            return {
                "response": result.get('response', ''),
                "tokens_used": result.get('tokens', 0),
                "from_cache": False
            }
    except Exception as exc:
        logger.error("model_inference_failed", tenant_id=tenant_id, model_name=model_name, error=str(exc))
        raise

@router.delete("/models/{model_name}")
async def delete_model(request: Request, model_name: str):
    """Delete AI model"""
    tenant_id = request.state.tenant_id
    model_id = f"{tenant_id}-{model_name}"
    
    logger.info("model_deletion_started", tenant_id=tenant_id, model_name=model_name)
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{settings.ollama_host}/api/delete",
                json={"name": model_name},
                timeout=10
            )
        return {"status": "deleted", "model_name": model_name}
    except Exception as exc:
        logger.error("model_deletion_failed", tenant_id=tenant_id, error=str(exc))
        raise
