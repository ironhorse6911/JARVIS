# Multi-stage JARVIS build with Ollama integration
# Stage 1: Base system with JARVIS scripts
FROM debian:12-slim as jarvis-base

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    net-tools \
    procps \
    findutils \
    grep \
    sed \
    bc \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy JARVIS scripts
COPY jarvis-*.sh ./
COPY create-model.sh ./
RUN chmod +x jarvis-*.sh create-model.sh

# Create jarvis user
RUN useradd -m -s /bin/bash jarvis && \
    mkdir -p /var/lib/jarvis /var/log/jarvis && \
    chown -R jarvis:jarvis /app /var/lib/jarvis /var/log/jarvis

# Stage 2: Python API layer
FROM jarvis-base as jarvis-api

WORKDIR /app

# Create Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy API requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy API code
COPY jarvis_api/ ./jarvis_api/
COPY config/ ./config/

# Stage 3: Runtime image
FROM debian:12-slim as jarvis-runtime

WORKDIR /app

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    net-tools \
    procps \
    findutils \
    grep \
    sed \
    bc \
    jq \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy from build stages
COPY --from=jarvis-base /app /app
COPY --from=jarvis-api /opt/venv /opt/venv

# Create runtime directories
RUN useradd -m -s /bin/bash jarvis && \
    mkdir -p /var/lib/jarvis /var/log/jarvis /data/ollama && \
    chown -R jarvis:jarvis /app /var/lib/jarvis /var/log/jarvis /data/ollama

WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH"
ENV JARVIS_LOG="/var/log/jarvis/operations.log"
ENV JARVIS_STATE="/var/lib/jarvis/system-state.json"
ENV OLLAMA_MODELS="/data/ollama/models"

EXPOSE 8000 5000 9090

USER jarvis

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default entrypoint
CMD ["/app/jarvis-launcher.sh"]
