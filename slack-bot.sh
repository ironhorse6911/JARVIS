#!/bin/bash
# JARVIS Slack Bot Integration
# Provides chat interface for JARVIS via Slack

set -euo pipefail

SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
JARVIS_API="${JARVIS_API:-http://localhost:8000}"

# Validate environment
if [[ -z "$SLACK_BOT_TOKEN" ]]; then
    echo "Error: SLACK_BOT_TOKEN not set" >&2
    exit 1
fi

# Handle Slack slash commands
handle_slash_command() {
    local command="$1"
    local text="$2"
    local user_id="$3"
    
    case "$command" in
        "/jarvis-scan")
            # Trigger security scan via API
            scan_type="${text:-standard}"
            response=$(curl -s -X POST "$JARVIS_API/api/v1/security/scan" \
                -H "Content-Type: application/json" \
                -H "X-Tenant-ID: slack" \
                -d "{\"scan_type\": \"$scan_type\"}")
            
            send_slack_message "Security scan initiated: $scan_type\n\`\`\`$(echo "$response" | jq .)\`\`\`"
            ;;
        "/jarvis-status")
            response=$(curl -s -X GET "$JARVIS_API/api/v1/performance/metrics" \
                -H "X-Tenant-ID: slack")
            
            send_slack_message "System Status:\n\`\`\`$(echo "$response" | jq .)\`\`\`"
            ;;
        "/jarvis-models")
            response=$(curl -s -X GET "$JARVIS_API/api/v1/models/list" \
                -H "X-Tenant-ID: slack")
            
            send_slack_message "Available Models:\n\`\`\`$(echo "$response" | jq .)\`\`\`"
            ;;
        *)
            send_slack_message "Unknown command: $command\nAvailable: /jarvis-scan, /jarvis-status, /jarvis-models"
            ;;
    esac
}

# Send message to Slack
send_slack_message() {
    local message="$1"
    
    curl -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"$message\"}"
}

# Main event handler
handle_event() {
    local event_type="$1"
    local payload="$2"
    
    case "$event_type" in
        "slash_command")
            # Parse command from payload
            handle_slash_command "$@"
            ;;
        "message")
            # Parse message and trigger appropriate action
            echo "Message event received" >&2
            ;;
    esac
}

# Server for webhook events
start_webhook_server() {
    echo "Starting Slack bot webhook server on port 3001..."
    
    python3 - <<'PYTHON_EOF'
from flask import Flask, request
import json

app = Flask(__name__)

@app.route('/slack/events', methods=['POST'])
def handle_slack_event():
    data = request.json
    
    if data.get('type') == 'url_verification':
        return data.get('challenge')
    
    if data.get('type') == 'event_callback':
        event = data.get('event', {})
        if event.get('type') == 'app_mention':
            # Handle @jarvis mentions
            print(f"JARVIS mentioned: {event}")
    
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3001)
PYTHON_EOF
}

# Start server
start_webhook_server
