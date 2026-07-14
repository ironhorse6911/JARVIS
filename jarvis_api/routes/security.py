"""Security scanning endpoints"""
from fastapi import APIRouter, Request, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import structlog
import subprocess
import asyncio

from jarvis_api.database import get_db
from jarvis_api.cache import get_cache

logger = structlog.get_logger(__name__)
router = APIRouter()

class ScanRequest(BaseModel):
    scan_type: str = "standard"  # quick, standard, deep
    include_network: bool = True
    include_auth: bool = True
    include_permissions: bool = True

class ScanResponse(BaseModel):
    scan_id: str
    tenant_id: str
    scan_type: str
    status: str
    start_time: datetime
    threats_detected: int
    details: dict

@router.post("/scan", response_model=ScanResponse)
async def start_security_scan(
    request: Request,
    scan_req: ScanRequest,
    db = Depends(get_db),
    cache = Depends(get_cache)
):
    """Initiate security scan"""
    tenant_id = request.state.tenant_id
    scan_id = f"{tenant_id}-{int(datetime.utcnow().timestamp())}"
    
    logger.info("security_scan_started", tenant_id=tenant_id, scan_type=scan_req.scan_type)
    
    try:
        # Execute security scan asynchronously
        result = await run_security_scan(scan_req.scan_type)
        
        # Cache result
        await cache.set(f"scan:{scan_id}", result, ttl=86400)
        
        return ScanResponse(
            scan_id=scan_id,
            tenant_id=tenant_id,
            scan_type=scan_req.scan_type,
            status="completed",
            start_time=datetime.utcnow(),
            threats_detected=result.get("threats", 0),
            details=result
        )
    except Exception as exc:
        logger.error("security_scan_failed", tenant_id=tenant_id, error=str(exc))
        raise

@router.get("/scan/{scan_id}")
async def get_scan_result(
    request: Request,
    scan_id: str,
    cache = Depends(get_cache)
):
    """Retrieve security scan results"""
    tenant_id = request.state.tenant_id
    
    # Validate tenant owns scan
    if not scan_id.startswith(f"{tenant_id}-"):
        return {"error": "Unauthorized access to scan"}
    
    result = await cache.get(f"scan:{scan_id}")
    if not result:
        return {"error": "Scan not found or expired"}
    
    return result

async def run_security_scan(scan_type: str = "standard") -> dict:
    """Execute security scan using shell commands"""
    threats = 0
    details = {
        "network_connections": [],
        "failed_logins": 0,
        "suspicious_processes": [],
        "world_writable_files": []
    }
    
    try:
        # Check network connections
        result = subprocess.run(
            ["ss", "-tulpn"],
            capture_output=True,
            text=True,
            timeout=10
        )
        details["network_connections"] = result.stdout.count("LISTEN")
        
        # Check failed logins
        result = subprocess.run(
            ["grep", "-c", "Failed password", "/var/log/auth.log"],
            capture_output=True,
            text=True,
            timeout=10
        )
        details["failed_logins"] = int(result.stdout.strip() or 0)
        if details["failed_logins"] > 5:
            threats += 1
        
        if scan_type == "deep":
            # Additional deep scan checks
            result = subprocess.run(
                ["find", "/etc", "-type", "f", "-perm", "/o+w"],
                capture_output=True,
                text=True,
                timeout=30
            )
            details["world_writable_files"] = result.stdout.strip().split("\n")
            if details["world_writable_files"]:
                threats += 1
    
    except Exception as exc:
        logger.error("security_scan_execution_error", error=str(exc))
    
    return {
        "threats": threats,
        "details": details,
        "scan_type": scan_type,
        "timestamp": datetime.utcnow().isoformat()
    }
