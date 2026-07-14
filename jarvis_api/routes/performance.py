"""Performance analysis endpoints"""
from fastapi import APIRouter, Request, Depends
from pydantic import BaseModel
from datetime import datetime
import structlog
import subprocess
import psutil

logger = structlog.get_logger(__name__)
router = APIRouter()

class MetricsResponse(BaseModel):
    tenant_id: str
    cpu_load: float
    memory_usage_mb: int
    memory_total_mb: int
    memory_percent: float
    disk_usage_percent: float
    top_processes: list
    timestamp: datetime

@router.get("/metrics", response_model=MetricsResponse)
async def get_performance_metrics(request: Request):
    """Get current system performance metrics"""
    tenant_id = request.state.tenant_id
    
    try:
        # CPU load
        cpu_load = os.getloadavg()[0] if hasattr(os, 'getloadavg') else 0.0
        
        # Memory
        mem = psutil.virtual_memory()
        
        # Disk
        disk = psutil.disk_usage('/')
        
        # Top processes
        top_procs = []
        for proc in psutil.process_iter(['pid', 'name', 'memory_percent', 'cpu_percent']):
            try:
                top_procs.append({
                    'pid': proc.info['pid'],
                    'name': proc.info['name'],
                    'memory_percent': proc.info['memory_percent'],
                    'cpu_percent': proc.info['cpu_percent']
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        top_procs = sorted(top_procs, key=lambda x: x['memory_percent'], reverse=True)[:5]
        
        return MetricsResponse(
            tenant_id=tenant_id,
            cpu_load=cpu_load,
            memory_usage_mb=mem.used // (1024 * 1024),
            memory_total_mb=mem.total // (1024 * 1024),
            memory_percent=mem.percent,
            disk_usage_percent=disk.percent,
            top_processes=top_procs,
            timestamp=datetime.utcnow()
        )
    except Exception as exc:
        logger.error("metrics_retrieval_error", tenant_id=tenant_id, error=str(exc))
        raise

@router.post("/optimize")
async def optimize_performance(request: Request, component: str = "all"):
    """Trigger system optimization"""
    tenant_id = request.state.tenant_id
    
    logger.info("optimization_started", tenant_id=tenant_id, component=component)
    
    # Call jarvis-system.sh optimize
    try:
        result = subprocess.run(
            ["bash", "-c", f"./jarvis-system.sh optimize {component}"],
            capture_output=True,
            text=True,
            timeout=60
        )
        return {
            "status": "completed",
            "component": component,
            "output": result.stdout
        }
    except Exception as exc:
        logger.error("optimization_failed", tenant_id=tenant_id, error=str(exc))
        return {"status": "error", "error": str(exc)}

import os
