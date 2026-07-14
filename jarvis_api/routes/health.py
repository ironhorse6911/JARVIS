"""Health check endpoint"""
from fastapi import APIRouter, Request
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check(request: Request):
    """Health check endpoint for container orchestration"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "JARVIS API",
        "version": "1.0.0",
        "tenant": getattr(request.state, "tenant_id", "default")
    }

@router.get("/ready")
async def readiness_check(request: Request):
    """Readiness check - indicates if service is ready for traffic"""
    return {
        "ready": True,
        "timestamp": datetime.utcnow().isoformat()
    }
