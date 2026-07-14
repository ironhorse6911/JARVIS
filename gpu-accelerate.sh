#!/bin/bash
# JARVIS GPU Acceleration Detection and Configuration
# Enables CUDA/Metal/ROCm support for faster model inference

set -euo pipefail

JARVIS_CONFIG="${JARVIS_CONFIG:-/var/lib/jarvis/gpu-config.json}"

detect_gpu() {
    echo "Detecting GPU availability..."
    
    local gpu_type="none"
    local gpu_devices=()
    
    # Check for NVIDIA CUDA
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_type="cuda"
        echo "✓ NVIDIA GPU detected (CUDA)"
        
        # Get GPU devices
        gpu_devices=($(nvidia-smi --query-gpu=name --format=csv,noheader | nl -w1 -s':' | tr '\n' ' '))
        echo "  Devices: ${gpu_devices[*]}"
        
        # Get CUDA version
        cuda_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
        echo "  Driver: $cuda_version"
    fi
    
    # Check for Apple Metal
    if [[ "$(uname)" == "Darwin" ]]; then
        if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Metal"; then
            gpu_type="metal"
            echo "✓ Apple Metal GPU detected"
        fi
    fi
    
    # Check for AMD ROCm
    if command -v rocm-smi >/dev/null 2>&1; then
        gpu_type="rocm"
        echo "✓ AMD GPU detected (ROCm)"
        rocm-smi --showid
    fi
    
    # Check for Intel oneAPI
    if command -v clpeak >/dev/null 2>&1; then
        gpu_type="intel"
        echo "✓ Intel GPU detected"
    fi
    
    echo "$gpu_type"
}

configure_ollama_gpu() {
    local gpu_type="$1"
    
    echo "Configuring Ollama for GPU acceleration ($gpu_type)..."
    
    case "$gpu_type" in
        "cuda")
            export OLLAMA_GPU=1
            echo "OLLAMA_GPU=1" >> /etc/environment
            echo "Ollama configured for CUDA"
            ;;
        "metal")
            export OLLAMA_METAL=1
            echo "OLLAMA_METAL=1" >> /etc/environment
            echo "Ollama configured for Metal"
            ;;
        "rocm")
            export OLLAMA_ROCM=1
            echo "OLLAMA_ROCM=1" >> /etc/environment
            echo "Ollama configured for ROCm"
            ;;
        "none")
            echo "No GPU detected. Using CPU inference (slower)"
            ;;
    esac
}

save_gpu_config() {
    local gpu_type="$1"
    local config=$(cat <<EOF
{
    "gpu_type": "$gpu_type",
    "detected_at": "$(date -Iseconds)",
    "cuda_available": $(command -v nvidia-smi >/dev/null && echo true || echo false),
    "metal_available": $([[ "$(uname)" == "Darwin" ]] && echo true || echo false),
    "rocm_available": $(command -v rocm-smi >/dev/null && echo true || echo false)
}
EOF
)
    
    mkdir -p "$(dirname "$JARVIS_CONFIG")"
    echo "$config" > "$JARVIS_CONFIG"
    echo "GPU configuration saved to $JARVIS_CONFIG"
}

benchmark_inference() {
    echo "Running model inference benchmark..."
    
    # Create small test prompt
    local test_prompt="What is 2+2?"
    
    # Measure inference time
    local start_time=$(date +%s%N)
    
    # Make API call
    curl -s -X POST "http://localhost:8000/api/v1/models/invoke/jarvis" \
        -H "Content-Type: application/json" \
        -d "{\"prompt\": \"$test_prompt\"}" >/dev/null
    
    local end_time=$(date +%s%N)
    local inference_time=$(( (end_time - start_time) / 1000000 ))
    
    echo "Inference latency: ${inference_time}ms"
}

main() {
    local gpu_type
    gpu_type=$(detect_gpu)
    
    configure_ollama_gpu "$gpu_type"
    save_gpu_config "$gpu_type"
    
    if [[ "$gpu_type" != "none" ]]; then
        benchmark_inference
    fi
}

main "$@"
