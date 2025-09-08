#!/bin/bash
#
# Iris - Logs & Monitoring Module for Daphne
# Location: ~/jessica/clara/iris.sh
#
# DESCRIPTION:
#   Iris is the observer of the Clara ecosystem. She helps you:
#     - View recent entries in key logs (deployment, audit, error)
#     - Tail logs in real time
#     - Check system service status (nginx, php-fpm, etc.)
#     - Show disk usage and uptime
#
#   All paths, colors, and log locations are loaded from the central config (dorian).
#   Iris is read-only: she never modifies logs or services, only reports on them.

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Function: View recent log entries ===
view_log() {
    local log_file="$1"
    local log_name="$2"
    echo -e "${GREEN}--- Last 20 entries from $log_name ---${NC}"
    if [[ -f "$log_file" ]]; then
        tail -n 20 "$log_file"
    else
        echo -e "${RED}Log file not found: $log_file${NC}"
    fi
}

# === Function: Tail a log in real time ===
tail_log() {
    local log_file="$1"
    local log_name="$2"
    echo -e "${GREEN}--- Tailing $log_name (Ctrl+C to stop) ---${NC}"
    if [[ -f "$log_file" ]]; then
        tail -f "$log_file"
    else
        echo -e "${RED}Log file not found: $log_file${NC}"
    fi
}

# === Function: Check core service status ===
check_services() {
    echo -e "${GREEN}--- Core Service Status ---${NC}"
    for svc in nginx php8.4-fpm; do
        echo -e "${YELLOW}$svc:${NC}"
        systemctl is-active --quiet "$svc" && echo -e "  ${GREEN}Active${NC}" || echo -e "  ${RED}Inactive${NC}"
    done
}

# === Function: Show disk usage ===
show_disk_usage() {
    echo -e "${GREEN}--- Disk Usage ---${NC}"
    df -h /
}

# === Function: Show system uptime ===
show_uptime() {
    echo -e "${GREEN}--- System Uptime ---${NC}"
    uptime
}

# === Iris's own submenu ===
while true; do
    echo
    echo "=== Iris: Logs & Monitoring ==="
    echo "1) View deployment log (last 20)"
    echo "2) View audit log (last 20)"
    echo "3) View error log (last 20)"
    echo "4) Tail deployment log"
    echo "5) Tail audit log"
    echo "6) Tail error log"
    echo "7) Check core service status"
    echo "8) Show disk usage"
    echo "9) Show system uptime"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) view_log "$DEPLOYMENT_LOG" "Deployment Log" ;;
        2) view_log "$AUDIT_LOG" "Audit Log" ;;
        3) view_log "$ERROR_LOG" "Error Log" ;;
        4) tail_log "$DEPLOYMENT_LOG" "Deployment Log" ;;
        5) tail_log "$AUDIT_LOG" "Audit Log" ;;
        6) tail_log "$ERROR_LOG" "Error Log" ;;
        7) check_services ;;
        8) show_disk_usage ;;
        9) show_uptime ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
