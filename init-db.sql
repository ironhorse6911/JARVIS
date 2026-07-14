# PostgreSQL database schema for JARVIS
-- Create audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    user_id VARCHAR(100),
    operation VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(100),
    status VARCHAR(50),
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_created (tenant_id, created_at),
    INDEX idx_operation (operation, created_at)
);

-- Create security scan results
CREATE TABLE IF NOT EXISTS security_scans (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    scan_type VARCHAR(100) NOT NULL,
    scan_level VARCHAR(50),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_seconds INT,
    threats_detected INT DEFAULT 0,
    threat_details JSONB,
    network_services JSONB,
    file_permissions JSONB,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_scan (tenant_id, created_at),
    INDEX idx_threats (threats_detected)
);

-- Create performance metrics
CREATE TABLE IF NOT EXISTS performance_metrics (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    metric_type VARCHAR(100) NOT NULL,
    cpu_load FLOAT,
    memory_usage_mb INT,
    memory_total_mb INT,
    disk_usage_percent FLOAT,
    swap_usage_mb INT,
    top_processes JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_metric (tenant_id, created_at)
);

-- Create AI models registry
CREATE TABLE IF NOT EXISTS ai_models (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    model_name VARCHAR(255) NOT NULL,
    base_model VARCHAR(255),
    persona VARCHAR(100),
    specialty VARCHAR(100),
    temperature FLOAT,
    status VARCHAR(50),
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, model_name),
    INDEX idx_tenant_models (tenant_id)
);

-- Create model inference logs
CREATE TABLE IF NOT EXISTS model_inferences (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    model_id INT REFERENCES ai_models(id),
    prompt TEXT,
    response TEXT,
    tokens_used INT,
    inference_time_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_model (tenant_id, model_id, created_at)
);

-- Create multi-tenant configuration
CREATE TABLE IF NOT EXISTS tenants (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) UNIQUE NOT NULL,
    tenant_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    features JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_api_key (api_key)
);

-- Create alert rules
CREATE TABLE IF NOT EXISTS alert_rules (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    trigger_condition VARCHAR(255),
    threshold INT,
    action VARCHAR(100),
    webhook_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_rules (tenant_id)
);

-- Create webhook logs
CREATE TABLE IF NOT EXISTS webhook_logs (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(100) NOT NULL,
    rule_id INT REFERENCES alert_rules(id),
    endpoint TEXT,
    payload JSONB,
    response_status INT,
    response_body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tenant_webhooks (tenant_id, created_at)
);

-- Create indexes for performance
CREATE INDEX idx_audit_timestamp ON audit_logs(created_at DESC);
CREATE INDEX idx_scan_timestamp ON security_scans(created_at DESC);
CREATE INDEX idx_metrics_timestamp ON performance_metrics(created_at DESC);
CREATE INDEX idx_inference_timestamp ON model_inferences(created_at DESC);
