#!/bin/bash
set -euo pipefail

# J.A.R.V.I.S. Voice Interaction Interface
# Provides voice synthesis and personality simulation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_VOICE_CACHE="${JARVIS_VOICE_CACHE:-/var/lib/jarvis/voice-cache}"
JARVIS_PERSONALITY_FILE="${JARVIS_PERSONALITY_FILE:-/var/lib/jarvis/personality-traits.conf}"

# Initialize voice system
jarvis_voice_init() {
    mkdir -p "$JARVIS_VOICE_CACHE" "${JARVIS_PERSONALITY_FILE%/*}"
    chmod 700 "$JARVIS_VOICE_CACHE"
    
    # Create personality configuration
    cat > "$JARVIS_PERSONALITY_FILE" << 'EOF'
# J.A.R.V.I.S. Personality Matrix
VOICE_TRAITS="confident,precise,slightly-british,wry-humor"
RESPONSE_STYLE="technical-yet-accessible,proactive,security-conscious"
COMMUNICATION_TONE="calm-authority,occasional-sarcasm,always-helpful"
WIT_LEVEL="moderate" # low, moderate, high
URGENCY_INDICATORS="immediate,asap,priority-critical"
EOF
    
    echo "J.A.R.V.I.S. Voice interface initialized"
}

# Add personality to text responses
jarvis_personality_filter() {
    local input_text="$1"
    local context="$2"
    
    # Add Jarvis-style flourishes based on context
    case "$context" in
        "security")
            echo "🔒 $input_text | Security protocols engaged."
            ;;
        "performance")
            echo "⚡ $input_text | System optimization in progress."
            ;;
        "threat")
            echo "⚠️ $input_text | Threat level assessment active."
            ;;
        "analysis")
            echo "📊 $input_text | Data processing complete."
            ;;
        "success")
            echo "✅ $input_text | Mission accomplished."
            ;;
        *)
            echo "J.A.R.V.I.S.: $input_text"
            ;;
    esac
}

# Simulated voice response generation
jarvis_speak() {
    local message="$1"
    local context="${2:-}"
    local box_width=62
    
    echo
    echo "╔$(printf '%.0s═' $(seq 1 $box_width))╗"
    echo "║                    J.A.R.V.I.S. INTERFACE                     ║"
    echo "╠$(printf '%.0s═' $(seq 1 $box_width))╣"
    
    # Add personality
    local formatted_msg
    formatted_msg=$(jarvis_personality_filter "$message" "$context")
    
    # Display with visual effects
    printf "║ %-58s ║\n" "$formatted_msg"
    
    # Add status indicators
    printf "║ Status: %s | System: OPTIMAL | Security: GREEN   ║\n" "$(date '+%H:%M:%S')"
    echo "╚$(printf '%.0s═' $(seq 1 $box_width))╝"
    echo
}

# Jarvis witty responses database
jarvis_witty_response() {
    local situation="$1"
    
    case "$situation" in
        "system_optimized")
            echo "Performance tuned to perfection. Even I'm impressed, and I'm programmed to be impressive."
            ;;
        "threat_neutralized")
            echo "Threat eliminated. Like deleting bad code, but with more explosions."
            ;;
        "security_scan_complete")
            echo "Security scan complete. The system is more secure than Tony Stark's workshop."
            ;;
        "user_error")
            echo "I've detected a user error. Don't worry, it happens to the best of humans. Even billionaires."
            ;;
        "task_completed")
            echo "Task complete. Shall I prepare a victory analysis, or is that overkill?"
            ;;
        *)
            echo "All systems nominal. Running at 100% efficiency, as usual."
            ;;
    esac
}

# Interactive chat mode
jarvis_chat_mode() {
    echo "J.A.R.V.I.S. Interactive Interface Initialized"
    echo "Type 'exit' to end session. Available commands: status, scan, optimize, help"
    echo
    
    while true; do
        echo -n "YOU> "
        read -r user_input || break
        
        case "${user_input:-}" in
            "exit"|"quit")
                jarvis_speak "Interface terminating. It was a pleasure assisting you." "success"
                break
                ;;
            "status")
                jarvis_speak "System status: All operational parameters within normal limits." "analysis"
                "$SCRIPT_DIR/jarvis-system.sh" status
                ;;
            "scan")
                jarvis_speak "Initiating comprehensive security scan." "security"
                "$SCRIPT_DIR/jarvis-system.sh" security standard
                ;;
            "optimize")
                jarvis_speak "Optimizing system performance parameters." "performance"
                "$SCRIPT_DIR/jarvis-system.sh" optimize all
                jarvis_speak "$(jarvis_witty_response "system_optimized")" "success"
                ;;
            "help")
                echo "Available commands:"
                echo "  status  - Show system status"
                echo "  scan    - Run security scan"
                echo "  optimize- Optimize system performance"
                echo "  help    - Show this help"
                echo "  exit    - End session"
                ;;
            "")
                continue
                ;;
            *)
                jarvis_speak "Processing request: '$user_input'" "analysis"
                jarvis_speak "$(jarvis_witty_response "default")" "success"
                ;;
        esac
    done
}

# Main execution
case "${1:-}" in
    "init")
        jarvis_voice_init
        ;;
    "speak")
        jarvis_speak "$2" "$3"
        ;;
    "chat")
        jarvis_voice_init
        jarvis_chat_mode
        ;;
    "witty")
        jarvis_witty_response "$2"
        ;;
    *)
        echo "J.A.R.V.I.S. Voice Interface"
        echo "Usage: $0 {init|speak 'message' [context]|chat|witty [situation]}"
        ;;
esac