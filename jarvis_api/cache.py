"""Cache layer using Redis"""
import json
import redis.asyncio as redis
from typing import Optional, Any
import structlog

from jarvis_api.config import Settings

logger = structlog.get_logger(__name__)
settings = Settings()

class CacheManager:
    """Redis-backed cache for model responses and session data"""
    
    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.redis = redis_client
    
    async def get(self, key: str) -> Optional[Any]:
        """Retrieve value from cache"""
        try:
            value = await self.redis.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as exc:
            logger.warning("cache_get_error", key=key, error=str(exc))
            return None
    
    async def set(self, key: str, value: Any, ttl: int = None) -> bool:
        """Store value in cache with TTL"""
        try:
            ttl = ttl or settings.cache_ttl
            await self.redis.setex(key, ttl, json.dumps(value))
            return True
        except Exception as exc:
            logger.warning("cache_set_error", key=key, error=str(exc))
            return False
    
    async def delete(self, key: str) -> bool:
        """Remove value from cache"""
        try:
            await self.redis.delete(key)
            return True
        except Exception as exc:
            logger.warning("cache_delete_error", key=key, error=str(exc))
            return False
    
    async def invalidate_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        try:
            keys = await self.redis.keys(pattern)
            if keys:
                return await self.redis.delete(*keys)
            return 0
        except Exception as exc:
            logger.warning("cache_invalidate_error", pattern=pattern, error=str(exc))
            return 0
    
    async def disconnect(self):
        """Close Redis connection"""
        if self.redis:
            await self.redis.close()

_cache_instance: Optional[CacheManager] = None

async def init_cache() -> CacheManager:
    """Initialize Redis cache connection"""
    global _cache_instance
    try:
        redis_client = await redis.from_url(settings.redis_url, decode_responses=True)
        _cache_instance = CacheManager(redis_client)
        await redis_client.ping()
        logger.info("cache_initialized", url=settings.redis_url)
        return _cache_instance
    except Exception as exc:
        logger.error("cache_initialization_failed", error=str(exc))
        raise

def get_cache() -> CacheManager:
    """Get cache instance"""
    if not _cache_instance:
        raise RuntimeError("Cache not initialized. Call init_cache() first.")
    return _cache_instance
