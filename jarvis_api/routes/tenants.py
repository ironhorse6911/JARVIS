"""Multi-tenant management endpoints"""
from fastapi import APIRouter, Request, Depends
from pydantic import BaseModel
from datetime import datetime
import structlog
import secrets

from jarvis_api.database import get_db

logger = structlog.get_logger(__name__)
router = APIRouter()

class TenantCreate(BaseModel):
    tenant_name: str
    contact_email: str

class TenantResponse(BaseModel):
    tenant_id: str
    tenant_name: str
    api_key: str
    created_at: datetime

@router.post("/create", response_model=TenantResponse)
async def create_tenant(
    request: Request,
    tenant: TenantCreate,
    db = Depends(get_db)
):
    """Create new tenant for multi-tenancy"""
    tenant_id = secrets.token_hex(8)
    api_key = secrets.token_urlsafe(32)
    
    logger.info("tenant_created", tenant_id=tenant_id, tenant_name=tenant.tenant_name)
    
    # TODO: Insert into tenants table
    
    return TenantResponse(
        tenant_id=tenant_id,
        tenant_name=tenant.tenant_name,
        api_key=api_key,
        created_at=datetime.utcnow()
    )

@router.get("/current")
async def get_current_tenant(request: Request):
    """Get current tenant information"""
    tenant_id = request.state.tenant_id
    return {
        "tenant_id": tenant_id,
        "api_key": request.state.api_key,
        "timestamp": datetime.utcnow().isoformat()
    }

@router.post("/api-keys/rotate")
async def rotate_api_key(request: Request, db = Depends(get_db)):
    """Rotate tenant API key"""
    tenant_id = request.state.tenant_id
    new_key = secrets.token_urlsafe(32)
    
    logger.info("api_key_rotated", tenant_id=tenant_id)
    
    # TODO: Update in database
    
    return {
        "tenant_id": tenant_id,
        "api_key": new_key,
        "rotated_at": datetime.utcnow().isoformat()
    }
