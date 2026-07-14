#!/bin/bash

MODEL_NAME="friday"
OLLAMA_MODEL="friday"

show_menu() {
    echo "$MODEL_NAME Management Interface"
    echo "1. Chat with $MODEL_NAME"
    echo "2. Rebuild Model"
    echo "3. Delete Model"
    echo "4. Model Info"
    echo "5. Exit"
}

case "$1" in
    "chat"|"")
        echo "Starting chat with $MODEL_NAME..."
        ollama run $OLLAMA_MODEL
        ;;
    "rebuild")
        echo "Rebuilding $MODEL_NAME..."
        ollama create $OLLAMA_MODEL -f Modelfile
        ;;
    "delete")
        echo "Deleting $OLLAMA_MODEL..."
        read -p "Confirm deletion of $OLLAMA_MODEL? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ollama rm $OLLAMA_MODEL
        fi
        ;;
    "info")
        echo "Model Information:"
        ollama show $OLLAMA_MODEL
        ;;
    *)
        show_menu
        ;;
esac
