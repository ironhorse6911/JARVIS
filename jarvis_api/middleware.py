"""Middleware for multi-tenant request handling"""
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import structlog

from jarvis_api.config import Settings

logger = structlog.get_logger(__name__)
settings = Settings()

class TenantMiddleware(BaseHTTPMiddleware):
    """Extract and validate tenant from request headers"""
    
    async def dispatch(self, request: Request, call_next):
        # Extract tenant from header or use default
        tenant_id = request.headers.get("X-Tenant-ID", settings.default_tenant)
        api_key = request.headers.get("X-API-Key")
        
        # Validate API key if provided
        if api_key and settings.enable_multi_tenant:
            # TODO: Validate against database
            if not await self._validate_api_key(api_key, tenant_id):
                return JSONResponse(
                    status_code=401,
                    content={"detail": "Invalid API key"}
                )
        
        # Add tenant to request state
        request.state.tenant_id = tenant_id
        request.state.api_key = api_key
        
        # Log request
        logger.info(
            "http_request",
            method=request.method,
            path=request.url.path,
            tenant_id=tenant_id
        )
        
        response = await call_next(request)
        return response
    
    async def _validate_api_key(self, api_key: str, tenant_id: str) -> bool:
        """Validate API key against database"""
        # TODO: Implement actual validation
        return True
