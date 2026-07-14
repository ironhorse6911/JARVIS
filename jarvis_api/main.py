"""
JARVIS FastAPI backend - Core application factory
Provides REST API for security scanning, performance analysis, model management, and multi-tenant support
"""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import structlog

from jarvis_api.database import init_db, get_db
from jarvis_api.cache import init_cache
from jarvis_api.routes import security, performance, models, tenants, webhooks, health
from jarvis_api.middleware import TenantMiddleware
from jarvis_api.config import Settings

logger = structlog.get_logger(__name__)
settings = Settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle events"""
    logger.info("JARVIS API initializing...", version="1.0.0")
    
    # Initialize database
    await init_db()
    
    # Initialize cache
    cache = await init_cache()
    app.state.cache = cache
    
    logger.info("JARVIS API ready")
    yield
    
    # Cleanup
    if cache:
        await cache.disconnect()
    logger.info("JARVIS API shutdown complete")

# Create FastAPI app
app = FastAPI(
    title="JARVIS AI Assistant API",
    description="Advanced security and performance analysis with multi-tenant AI integration",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for web dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom tenant middleware
app.add_middleware(TenantMiddleware)

# Register route modules
app.include_router(health.router, tags=["Health"])
app.include_router(security.router, prefix="/api/v1/security", tags=["Security"])
app.include_router(performance.router, prefix="/api/v1/performance", tags=["Performance"])
app.include_router(models.router, prefix="/api/v1/models", tags=["Models"])
app.include_router(tenants.router, prefix="/api/v1/tenants", tags=["Tenants"])
app.include_router(webhooks.router, prefix="/api/v1/webhooks", tags=["Webhooks"])

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global error handler with structured logging"""
    logger.error("unhandled_exception", exc_info=exc, path=request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "trace_id": str(id(exc))}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "jarvis_api.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )
