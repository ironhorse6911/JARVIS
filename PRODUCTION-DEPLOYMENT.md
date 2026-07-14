# JARVIS: Comprehensive Production-Ready System

## Quick Start

### Docker Compose (Local Development)
```bash
docker compose up --pull always
```

Connects: API (8000), Grafana (3000), Prometheus (9090), Ollama (11434), PostgreSQL (5432)

### Kubernetes (Production)
```bash
kubectl apply -f k8s-infrastructure.yaml
kubectl apply -f k8s-api-deployment.yaml
kubectl port-forward -n jarvis svc/jarvis-api 8000:8000
```

### Systemd Service (Bare Metal)
```bash
sudo cp jarvis.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now jarvis
```

---

## Architecture

### Components

**Backend API (FastAPI)**
- Multi-tenant REST API with Swagger docs
- Security scanning, performance analysis, model management
- Database audit logs, webhook alerts
- Prometheus metrics export
- Location: `/api/v1/` 

**Database (PostgreSQL)**
- Audit logs, scan history, model registry, alert rules
- Multi-tenant schema with tenant isolation
- Initialized via `init-db.sql` migration

**Cache (Redis)**
- Session management, response caching
- Model inference cache (1-hour TTL)
- Webhook queue for async delivery

**LLM Runtime (Ollama)**
- Model serving and inference
- Support for multiple personalities (JARVIS, FRIDAY, CODEX, ANALYST)
- GPU acceleration (CUDA/Metal/ROCm)

**Monitoring (Prometheus + Grafana)**
- Security scan metrics, threat detection counts
- API request rates, model inference latency
- System CPU/memory utilization
- Pre-built dashboards at `http://localhost:3000`

**Orchestration (Kubernetes)**
- 3-replica Deployment with auto-scaling (2-10 replicas)
- StatefulSet for Ollama with persistent model storage
- Horizontal Pod Autoscaler on CPU/memory metrics

---

## API Endpoints

### Security
- `POST /api/v1/security/scan` - Start security scan (quick/standard/deep)
- `GET /api/v1/security/scan/{scan_id}` - Retrieve scan results

### Performance
- `GET /api/v1/performance/metrics` - System metrics (CPU, memory, disk)
- `POST /api/v1/performance/optimize` - Trigger optimization

### Models
- `GET /api/v1/models/list` - List available Ollama models
- `POST /api/v1/models/create` - Create new AI model
- `POST /api/v1/models/invoke/{model_name}` - Run inference
- `DELETE /api/v1/models/{model_name}` - Delete model

### Multi-Tenancy
- `POST /api/v1/tenants/create` - Create tenant with API key
- `GET /api/v1/tenants/current` - Get current tenant info
- `POST /api/v1/tenants/api-keys/rotate` - Rotate API key

### Webhooks
- `POST /api/v1/webhooks/register` - Register alert webhook
- `POST /api/v1/webhooks/test/{webhook_id}` - Test webhook

### Metrics
- `GET /metrics` - Prometheus metrics in text format

---

## Multi-Tenancy

Each tenant is isolated by:
- Unique `X-Tenant-ID` header (defaults to "default")
- API key validation (`X-API-Key` header)
- Database row-level security via tenant_id foreign key
- Separate model caches and audit logs

Example request:
```bash
curl -X GET http://localhost:8000/api/v1/security/scan/tenant-1-scan-123 \
  -H "X-Tenant-ID: tenant-1" \
  -H "X-API-Key: your-secret-key"
```

---

## GPU Acceleration

Automatically detect and enable:
- **NVIDIA CUDA** → `OLLAMA_GPU=1`
- **Apple Metal** → `OLLAMA_METAL=1`
- **AMD ROCm** → `OLLAMA_ROCM=1`

Run detection:
```bash
bash gpu-accelerate.sh
```

Saves configuration to `/var/lib/jarvis/gpu-config.json`

---

## Slack Integration

Register bot with Slack, then:
- `/jarvis-scan [quick|standard|deep]` - Trigger security scan
- `/jarvis-status` - Get system metrics
- `/jarvis-models` - List available models

Setup:
```bash
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_WEBHOOK_URL=https://hooks.slack.com/...
bash slack-bot.sh
```

---

## Monitoring & Alerts

**Prometheus Metrics** (auto-scraped every 30s):
- `jarvis_security_scans_total` - Total scans by type
- `jarvis_threats_detected_total` - Threats by category
- `jarvis_model_inference_duration_ms` - Model latency (histogram)
- `jarvis_system_memory_percent` - System memory usage
- `jarvis_active_models` - Active models per tenant

**Grafana Dashboards**:
- Security overview (threats, scan duration, types)
- Performance trends (CPU, memory, disk)
- Model inference latency and cache hit rates
- Tenant usage and API rate limits

Access at `http://localhost:3000` (admin/admin)

---

## CI/CD Pipeline

GitHub Actions workflow:
1. **Lint** - shellcheck, hadolint
2. **Test** - Python API tests, bash script validation
3. **Build** - Multi-stage Docker build
4. **Security** - Trivy vulnerability scan
5. **Deploy** - Push to K8s on merge to main

Triggers on: push to main/develop, pull requests

---

## Configuration

### Environment Variables
```bash
# API
JARVIS_ENV=production
LOG_LEVEL=INFO

# Database
DATABASE_URL=postgresql://jarvis:pass@postgres:5432/jarvis

# Redis
REDIS_URL=redis://redis:6379

# Ollama
OLLAMA_HOST=http://ollama:11434
DEFAULT_MODEL=jarvis

# GPU
OLLAMA_GPU=1  # or OLLAMA_METAL=1, OLLAMA_ROCM=1
```

### Systemd Service
Installs to `/opt/jarvis`, runs as `jarvis:jarvis` user, auto-restart on failure.

View logs:
```bash
sudo journalctl -u jarvis -f
```

---

## File Structure

```
.
├── Dockerfile              # Multi-stage build
├── docker-compose.yml      # Local dev orchestration
├── requirements.txt        # Python dependencies
├── jarvis_api/             # FastAPI backend
│   ├── main.py            # App factory
│   ├── config.py          # Settings
│   ├── database.py        # SQLAlchemy setup
│   ├── cache.py           # Redis layer
│   ├── middleware.py      # Tenant middleware
│   ├── metrics.py         # Prometheus metrics
│   └── routes/
│       ├── health.py
│       ├── security.py
│       ├── performance.py
│       ├── models.py
│       ├── tenants.py
│       └── webhooks.py
├── init-db.sql            # Database schema
├── prometheus.yml         # Metrics scrape config
├── k8s-*.yaml            # Kubernetes manifests
├── jarvis.service        # Systemd unit
├── gpu-accelerate.sh     # GPU detection
├── slack-bot.sh          # Slack integration
└── .github/workflows/    # CI/CD pipeline
```

---

## Next Steps

1. **Set database password**: Update `POSTGRES_PASSWORD` in docker-compose.yml and `.env`
2. **Configure Slack bot**: Get token from Slack API console, set in environment
3. **Deploy to Kubernetes**: Update image registry, secrets, and kubectl context
4. **Create custom models**: Use `POST /api/v1/models/create` or `bash create-model.sh`
5. **Monitor metrics**: Access Grafana at localhost:3000
6. **Scale deployment**: HPA auto-scales on CPU (70%) and memory (80%) usage
7. **Set up alerts**: Register webhooks for threat/performance thresholds

---

## Support & Customization

All scripts are production-hardened with:
- Error handling and logging
- Multi-tenant isolation
- Resource limits and security contexts
- Health checks and graceful shutdown
- GPU acceleration detection
- Container orchestration readiness

Extend via:
- Custom SecurityScan subclasses in `jarvis_api/routes/security.py`
- New model personas in `create-model.sh`
- Additional webhook integrations
- Slack/Discord/Teams bot handlers
