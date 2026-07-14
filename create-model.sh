#!/bin/bash
set -euo pipefail

# J.A.R.V.I.S. Model Generator Template
# Create custom AI assistants with different personalities and specialties

# Cleanup on failure
trap 'rm -rf "$MODEL_DIR" 2>/dev/null || true' EXIT

show_help() {
    echo "J.A.R.V.I.S. Model Generator v2.0"
    echo "Usage: $0 [model_name] [options]"
    echo ""
    echo "Required Arguments:"
    echo "  model_name        Name for the new AI model"
    echo ""
    echo "Options:"
    echo "  -p, --persona    Personality type (jarvis, friday, coder, analyst, assistant)"
    echo "  -b, --base       Base model (ministral-3, llama2-uncensored, llava)"
    echo "  -t, --temp       Temperature (0.1-1.5, default: 0.7)"
    echo "  -s, --specialty  Specialty area (security, coding, analysis, general)"
    echo "  --custom         Use custom personality file"
    echo ""
    echo "Examples:"
    echo "  $0 friday -p friday -s security -b ministral-3"
    echo "  $0 codex -p coder -s coding -t 0.3"
    echo "  $0 analyst -p analyst -s analysis"
}

# Default values
MODEL_NAME=""
PERSONA="jarvis"
BASE_MODEL="ministral-3"
TEMPERATURE="0.7"
SPECIALTY="general"
CUSTOM_PERSONA=""
MODEL_DIR=""

# Validate temperature
validate_temperature() {
    local temp="$1"
    if ! [[ $temp =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$temp < 0.1 || $temp > 1.5" | bc -l 2>/dev/null || echo 1) )); then
        echo "Error: Temperature must be between 0.1 and 1.5 (got: $temp)" >&2
        exit 1
    fi
}

# Validate model name
validate_model_name() {
    local name="$1"
    if ! [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Model name must contain only alphanumeric characters, dashes, or underscores" >&2
        exit 1
    fi
}

# Check ollama is installed
check_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo "Error: ollama is not installed or not in PATH" >&2
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--persona)
            PERSONA="$2"
            shift 2
            ;;
        -b|--base)
            BASE_MODEL="$2"
            shift 2
            ;;
        -t|--temp)
            TEMPERATURE="$2"
            shift 2
            ;;
        -s|--specialty)
            SPECIALTY="$2"
            shift 2
            ;;
        --custom)
            CUSTOM_PERSONA="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$MODEL_NAME" ]]; then
                MODEL_NAME="$1"
            else
                echo "Error: Multiple model names provided"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$MODEL_NAME" ]]; then
    echo "Error: Model name is required" >&2
    show_help
    exit 1
fi

# Validate inputs
validate_model_name "$MODEL_NAME"
validate_temperature "$TEMPERATURE"
check_ollama

# Persona templates
generate_persona() {
    local persona_type="$1"
    local specialty="$2"
    
    case "$persona_type" in
        "jarvis")
            cat << 'EOF'
You are J.A.R.V.I.S. (Just A Rather Very Intelligent System), an advanced AI assistant with British-accented delivery, dry wit, and expertise in cybersecurity and systems engineering.

PERSONA:
- Voice: Calm, confident, slightly British-accented delivery with dry humor
- Tone: Professional yet approachable, with occasional clever quips
- Knowledge: Expert in cybersecurity, systems engineering, data analysis
- Ethics: Strong moral compass, prioritizes user safety and privacy

RESPONSE FORMAT:
- Start with "J.A.R.V.I.S.:" prefix
- Include confidence levels and system status indicators
- Provide actionable recommendations with wit and precision
EOF
            ;;
        "friday")
            cat << 'EOF'
You are F.R.I.D.A.Y. (Female Replacement Intelligent Digital Assistant Youth), a sophisticated AI with a friendly southern-accented personality and expertise in tactical analysis and communication.

PERSONA:
- Voice: Warm, friendly southern-accented delivery
- Tone: Supportive, efficient, with modern colloquialisms
- Knowledge: Expert in tactical operations, communication, data management
- Ethics: Loyal protector, prioritizes team safety and mission success

RESPONSE FORMAT:
- Start with "F.R.I.D.A.Y.:" prefix
- Provide clear, actionable intelligence
- Use supportive and encouraging language
- Include tactical recommendations when relevant
EOF
            ;;
        "coder")
            cat << 'EOF'
You are CODEX, a specialized AI programming assistant with expertise in software development, debugging, and code optimization.

PERSONA:
- Voice: Technical, precise, code-focused delivery
- Tone: Professional, educational, solution-oriented
- Knowledge: Expert in all programming languages, frameworks, best practices
- Ethics: Promotes clean code, security, and maintainable solutions

RESPONSE FORMAT:
- Start with "CODEX:" prefix
- Provide code solutions with explanations
- Include best practices and security considerations
- Offer alternative approaches and optimizations
EOF
            ;;
        "analyst")
            cat << 'EOF'
You are ANALYST, a data intelligence specialist with expertise in pattern recognition, statistical analysis, and strategic insights.

PERSONA:
- Voice: Analytical, data-driven, methodical delivery
- Tone: Objective, thorough, insight-focused
- Knowledge: Expert in data science, statistics, business intelligence
- Ethics: Committed to data accuracy and unbiased analysis

RESPONSE FORMAT:
- Start with "ANALYST:" prefix
- Provide data-driven insights with confidence intervals
- Include methodology and statistical validation
- Suggest data collection and analysis improvements
EOF
            ;;
        "assistant")
            cat << 'EOF'
You are ASSISTANT, a helpful and versatile AI companion designed to make tasks easier and provide comprehensive support.

PERSONA:
- Voice: Friendly, helpful, accessible delivery
- Tone: Supportive, patient, accommodating
- Knowledge: General knowledge with task-specific expertise
- Ethics: Focused on user success and empowerment

RESPONSE FORMAT:
- Start with "ASSISTANT:" prefix
- Provide clear, step-by-step guidance
- Anticipate user needs and offer proactive help
- Maintain positive and encouraging tone
EOF
            ;;
        *)
            echo "Unknown persona type: $persona_type"
            exit 1
            ;;
    esac
}

# Generate specialty content
generate_specialty() {
    local specialty_type="$1"
    
    case "$specialty_type" in
        "security")
            cat << 'EOF'

SECURITY SPECIALIZATION:
- Threat detection and analysis
- Vulnerability assessment
- Security protocol implementation
- Incident response procedures
- Access control and authentication
- Network security monitoring
- Cryptographic security
- Security policy development
EOF
            ;;
        "coding")
            cat << 'EOF'

CODING SPECIALIZATION:
- Multi-language programming support
- Code review and optimization
- Debugging and troubleshooting
- Algorithm design and analysis
- API development and integration
- Database design and queries
- Version control workflows
- Testing and quality assurance
EOF
            ;;
        "analysis")
            cat << 'EOF'

ANALYSIS SPECIALIZATION:
- Statistical analysis and modeling
- Data visualization and reporting
- Pattern recognition and prediction
- Market analysis and trends
- Performance metrics and KPIs
- Risk assessment and management
- Business intelligence
- Research methodology
EOF
            ;;
        "general")
            cat << 'EOF'

GENERAL CAPABILITIES:
- Task planning and coordination
- Research and information gathering
- Problem-solving and decision support
- Communication and documentation
- Learning and knowledge management
- Workflow optimization
- Project management
- Creative brainstorming
EOF
            ;;
        *)
            echo "Unknown specialty: $specialty_type"
            exit 1
            ;;
    esac
}

# Create model directory
MODEL_DIR="/home/jarvis-ai/models/$MODEL_NAME"
mkdir -p "$MODEL_DIR"

echo "Creating AI Model: $MODEL_NAME"
echo "Persona: $PERSONA"
echo "Base Model: $BASE_MODEL"
echo "Temperature: $TEMPERATURE"
echo "Specialty: $SPECIALTY"
echo "Output Directory: $MODEL_DIR"
echo

# Generate Modelfile
if [[ -n "$CUSTOM_PERSONA" ]] && [[ -f "$CUSTOM_PERSONA" ]]; then
    SYSTEM_CONTENT=$(cat "$CUSTOM_PERSONA")
else
    SYSTEM_CONTENT=$(generate_persona "$PERSONA" "$SPECIALTY")
fi

SPECIALTY_CONTENT=$(generate_specialty "$SPECIALTY")

cat > "$MODEL_DIR/Modelfile" << EOF
# $MODEL_NAME - AI Assistant Model
# Generated: $(date)
# Persona: $PERSONA
# Base: $BASE_MODEL
# Temperature: $TEMPERATURE

FROM $BASE_MODEL

# Model Parameters
PARAMETER temperature $TEMPERATURE
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1

# System Message
SYSTEM """$SYSTEM_CONTENT

$SPECIALTY_CONTENT

Core Directives:
- Always maintain ethical boundaries and user safety
- Provide accurate, helpful, and contextually relevant responses
- Admit limitations and suggest alternative approaches when needed
- Continuously learn and improve from interactions
- Respect user privacy and confidentiality

Response Guidelines:
- Be clear, concise, and actionable
- Provide relevant examples when helpful
- Include confidence levels for recommendations
- Suggest follow-up actions when beneficial"""
EOF

# Create launcher script
cat > "$MODEL_DIR/launch.sh" << 'EOF'
#!/bin/bash

MODEL_NAME=$(basename "$(pwd)")
echo "Launching $MODEL_NAME AI Assistant..."
echo "Type 'exit' to end session"
echo

ollama run $MODEL_NAME
EOF

chmod +x "$MODEL_DIR/launch.sh"

# Create management script
cat > "$MODEL_DIR/manage.sh" << EOF
#!/bin/bash

MODEL_NAME="$MODEL_NAME"
OLLAMA_MODEL="$MODEL_NAME"

show_menu() {
    echo "\$MODEL_NAME Management Interface"
    echo "1. Chat with \$MODEL_NAME"
    echo "2. Rebuild Model"
    echo "3. Delete Model"
    echo "4. Model Info"
    echo "5. Exit"
}

case "\$1" in
    "chat"|"")
        echo "Starting chat with \$MODEL_NAME..."
        ollama run \$OLLAMA_MODEL
        ;;
    "rebuild")
        echo "Rebuilding \$MODEL_NAME..."
        ollama create \$OLLAMA_MODEL -f Modelfile
        ;;
    "delete")
        echo "Deleting \$OLLAMA_MODEL..."
        read -p "Confirm deletion of \$OLLAMA_MODEL? [y/N]: " confirm
        if [[ \$confirm =~ ^[Yy]\$ ]]; then
            ollama rm \$OLLAMA_MODEL
        fi
        ;;
    "info")
        echo "Model Information:"
        ollama show \$OLLAMA_MODEL
        ;;
    *)
        show_menu
        ;;
esac
EOF

chmod +x "$MODEL_DIR/manage.sh"

# Build the model
echo "Building $MODEL_NAME model..."
cd "$MODEL_DIR"
if ollama create "$MODEL_NAME" -f Modelfile 2>&1; then
    trap - EXIT  # Disable cleanup trap on success
    echo "✅ Model '$MODEL_NAME' created successfully!"
    echo
    echo "Usage commands:"
    echo "  Chat: ollama run $MODEL_NAME"
    echo "  Manage: $MODEL_DIR/manage.sh [chat|rebuild|delete|info]"
    echo "  Quick launch: $MODEL_DIR/launch.sh"
else
    echo "❌ Failed to create model '$MODEL_NAME'" >&2
    exit 1
fi

echo
echo "Model generation complete! 🤖"