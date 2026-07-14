#!/bin/bash
set -euo pipefail

# J.A.R.V.I.S. Launcher Script
# Complete high-tech AI assistant interface

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    J.A.R.V.I.S. SYSTEM                     ║"
echo "║              Just A Rather Very Intelligent System        ║"
echo "║                 Advanced AI Assistant v1.0                ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Initialize Jarvis system
"$SCRIPT_DIR/jarvis-system.sh" init

# Show available commands
echo
echo "J.A.R.V.I.S. Interface Options:"
echo "1. Interactive Chat Mode"
echo "2. Security Analysis"
echo "3. Performance Optimization"
echo "4. System Status"
echo "5. Voice Interface"
echo "6. Exit"
echo

while true; do
    echo -n "Select J.A.R.V.I.S. operation [1-6]: "
    read -r choice
    
    case $choice in
        1)
            echo "J.A.R.V.I.S.: Activating interactive interface..."
            ollama run jarvis
            ;;
        2)
            echo "J.A.R.V.I.S.: Running security diagnostics..."
            "$SCRIPT_DIR/jarvis-system.sh" security standard
            ;;
        3)
            echo "J.A.R.V.I.S.: Optimizing system performance..."
            "$SCRIPT_DIR/jarvis-system.sh" optimize all
            ;;
        4)
            echo "J.A.R.V.I.S.: Current system status..."
            "$SCRIPT_DIR/jarvis-system.sh" status
            ;;
        5)
            echo "J.A.R.V.I.S.: Initializing voice interface..."
            "$SCRIPT_DIR/jarvis-voice.sh" chat
            ;;
        6)
            echo "J.A.R.V.I.S.: Interface terminating. It was a pleasure serving you."
            exit 0
            ;;
        *)
            echo "J.A.R.V.I.S.: Invalid selection. Please choose 1-6."
            ;;
    esac
    echo
done