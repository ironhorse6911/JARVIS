#!/bin/bash

MODEL_NAME=$(basename "$(pwd)")
echo "Launching $MODEL_NAME AI Assistant..."
echo "Type 'exit' to end session"
echo

ollama run $MODEL_NAME
