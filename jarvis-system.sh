#!/bin/bash
set -euo pipefail

# J.A.R.V.I.S. Cybersecurity & System Management Integration Script
# This script provides Jarvis with system control and monitoring capabilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_LOG="${JARVIS_LOG:-/var/log/jarvis-operations.log}"
JARVIS_STATE="${JARVIS_STATE:-/var/lib/jarvis/system-state.json}"

# Initialize Jarvis environment
jarvis_init() {
    echo "J.A.R.V.I.S. Initialization Sequence Started..." | tee -a "$JARVIS_LOG"
    mkdir -p "${JARVIS_STATE%/*}" "${JARVIS_LOG%/*}"
    chmod 700 "${JARVIS_STATE%/*}"
    
    # Create system state tracking
    cat > "$JARVIS_STATE" << EOF
{
    "status": "ONLINE",
    "security_level": "GREEN",
    "last_scan": "$(date -Iseconds)",
    "threats_detected": 0,
    "performance_optimizations": 0,
    "uptime": "$(uptime -p)"
}
EOF
    
    echo "J.A.R.V.I.S. systems nominal. All protocols active." | tee -a "$JARVIS_LOG"
}

# Security Analysis Function
jarvis_security_scan() {
    local scan_type=${1:-"standard"}
    echo "J.A.R.V.I.S.: Initiating security scan - Level: $scan_type" | tee -a "$JARVIS_LOG"
    
    case $scan_type in
        "quick")
            # Quick security checks
            echo "Quick Security Analysis:" 
            echo "- Active network connections: $(ss -tulpn | wc -l)"
            echo "- Failed login attempts: $(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)"
            echo "- Running services: $(systemctl list-units --type=service --state=running | wc -l)"
            ;;
        "standard")
            # Comprehensive security scan
            echo "Standard Security Analysis:"
            echo "Network Services:"
            ss -tulpn | grep LISTEN | head -10
            echo "Recent Security Events:"
            tail -20 /var/log/auth.log 2>/dev/null | grep -E "(Failed|Invalid|error)" || echo "No security events detected"
            echo "File Permissions Check:"
            find /etc -type f -perm /o+w 2>/dev/null | head -5 || echo "No world-writable config files found"
            ;;
        "deep")
            # Deep security analysis
            echo "Deep Security Analysis Initiated..."
            echo "Port Scanning Results:"
            netstat -tuln | grep LISTEN
            echo "User Authentication Analysis:"
            last -n 10 | head -5
            echo "Process Security Check:"
            ps aux | grep -E "(root|sudo)" | grep -v grep | head -5
            ;;
    esac
    
    echo "Security scan completed at $(date)" | tee -a "$JARVIS_LOG"
}

# Performance Analysis
jarvis_performance_analysis() {
    echo "J.A.R.V.I.S.: Running performance diagnostics..." | tee -a "$JARVIS_LOG"
    
    echo "System Performance Metrics:"
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | grep Mem | awk '{printf "%s/%s (%.1f%%)", $3,$2,$3/$2*100}')"
    echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
    echo "Swap Usage: $(free -h | grep Swap | awk '{print $3}')"
    
    echo "Top Resource Consumers:"
    echo "Memory:"
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %-15s %.1f%%\n", $11, $4}'
    echo "CPU:"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-15s %.1f%%\n", $11, $3}'
    
    echo "Performance analysis completed at $(date)" | tee -a "$JARVIS_LOG"
}

# System Optimization
jarvis_optimize() {
    local component=${1:-"all"}
    echo "J.A.R.V.I.S.: Optimizing $component systems..." | tee -a "$JARVIS_LOG"
    
    case $component in
        "memory")
            echo "Memory optimization procedures:"
            # Clear caches safely (requires root)
            if [[ $EUID -eq 0 ]]; then
                sync && echo 1 > /proc/sys/vm/drop_caches 2>/dev/null && echo "Cache cleared"
                echo "Memory swappiness: $(cat /proc/sys/vm/swappiness)"
            else
                echo "Memory optimization requires root privileges. Skipping cache clear."
            fi
            ;;
        "network")
            echo "Network optimization:"
            echo "TCP settings:"
            sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem 2>/dev/null || echo "Network tuning skipped (requires root)"
            ;;
        "all")
            echo "Comprehensive system optimization:"
            echo "- Cleaning temporary files..."
            find /tmp -type f -atime +7 -delete 2>/dev/null || echo "Temp cleanup skipped (no permission)"
            echo "- Checking disk space..."
            df -h | head -5
            echo "- System load optimization complete"
            ;;
    esac
    
    echo "Optimization completed at $(date)" | tee -a "$JARVIS_LOG"
}

# Threat Detection
jarvis_threat_monitor() {
    echo "J.A.R.V.I.S.: Monitoring for active threats..." | tee -a "$JARVIS_LOG"
    
    local threats=0
    
    # Check for suspicious processes
    if pgrep -f "(nc|netcat|nmap)" >/dev/null 2>&1; then
        echo "WARNING: Suspicious network tools detected" >&2
        ((threats++))
    fi
    
    # Check for unusual network connections
    local suspicious_conns
    suspicious_conns=$(ss -tulpn 2>/dev/null | grep -cE ":(4444|5555|6666|7777|8888)" || echo 0)
    if [ "$suspicious_conns" -gt 0 ]; then
        echo "WARNING: Suspicious port activity detected" >&2
        ((threats++))
    fi
    
    # Check authentication failures
    local auth_failures
    auth_failures=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo 0)
    if [ "$auth_failures" -gt 5 ]; then
        echo "WARNING: Multiple authentication failures detected" >&2
        ((threats++))
    fi
    
    if [ $threats -eq 0 ]; then
        echo "No active threats detected. System secure."
    else
        echo "THREAT LEVEL ELEVATED: $threats potential threats identified" >&2
    fi
    
    echo "Threat monitoring check completed at $(date)" | tee -a "$JARVIS_LOG"
}

# Main command interface
case "${1:-}" in
    "init")
        jarvis_init
        ;;
    "security")
        jarvis_security_scan "$2"
        ;;
    "performance") 
        jarvis_performance_analysis
        ;;
    "optimize")
        jarvis_optimize "$2"
        ;;
    "monitor")
        jarvis_threat_monitor
        ;;
    "status")
        echo "J.A.R.V.I.S. System Status:"
        cat "$JARVIS_STATE" 2>/dev/null || echo "Status file not found"
        ;;
    *)
        echo "J.A.R.V.I.S. System Management Interface"
        echo "Usage: $0 {init|security [quick|standard|deep]|performance|optimize [memory|network|all]|monitor|status}"
        exit 1
        ;;
esac