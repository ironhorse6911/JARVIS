"""Prometheus metrics export"""
from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry
from fastapi import APIRouter
from prometheus_client.exposition import generate_latest

router = APIRouter()

# Create metrics registry
registry = CollectorRegistry()

# Counter metrics
security_scans_total = Counter(
    'jarvis_security_scans_total',
    'Total security scans executed',
    ['scan_type', 'tenant_id'],
    registry=registry
)

threats_detected_total = Counter(
    'jarvis_threats_detected_total',
    'Total threats detected',
    ['threat_type', 'tenant_id'],
    registry=registry
)

api_requests_total = Counter(
    'jarvis_api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status'],
    registry=registry
)

# Histogram metrics
security_scan_duration_seconds = Histogram(
    'jarvis_security_scan_duration_seconds',
    'Security scan duration in seconds',
    ['scan_type'],
    registry=registry
)

model_inference_duration_ms = Histogram(
    'jarvis_model_inference_duration_ms',
    'Model inference latency in milliseconds',
    ['model_name'],
    registry=registry,
    buckets=[10, 100, 500, 1000, 2000, 5000]
)

# Gauge metrics
active_models_gauge = Gauge(
    'jarvis_active_models',
    'Number of active models',
    ['tenant_id'],
    registry=registry
)

system_memory_percent = Gauge(
    'jarvis_system_memory_percent',
    'System memory usage percentage',
    registry=registry
)

system_cpu_load = Gauge(
    'jarvis_system_cpu_load',
    'System CPU load',
    registry=registry
)

@router.get("/metrics")
async def metrics():
    """Export Prometheus metrics"""
    return generate_latest(registry)
