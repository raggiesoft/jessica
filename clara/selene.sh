#!/bin/bash
#
# Selene - Update Cycle Module for Daphne
# Location: ~/jessica/clara/selene.sh
#
# DESCRIPTION:
#   Selene keeps the glowing-galaxy environment up to date.
#   She can:
#     - Update OS packages
#     - Update the Jessica suite via Clio (Git)
#     - Clean up unused packages and caches
#     - Restart core services
#     - Run a full update cycle (all of the above in sequence)
#
#   All paths, colors, and logs are loaded from the central config (dorian).

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# === Function: Update OS Packages ===
update_os() {
    echo -e "${GREEN}--- Updating OS packages ---${NC}"
    echo "$(date '+%F %T') | Selene | OS update started" >> "$AUDIT_LOG"

    if sudo apt-get update && sudo apt-get -y upgrade; then
        echo -e "${GREEN}OS packages updated successfully.${NC}"
    else
        echo -e "${RED}OS update failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Selene | OS update failed" >> "$ERROR_LOG"
    fi
}

# === Function: Update Jessica Modules via Clio ===
update_modules() {
    echo -e "${GREEN}--- Updating Jessica suite via Clio ---${NC}"
    echo "$(date '+%F %T') | Selene | Module update started" >> "$AUDIT_LOG"

    if "$SCRIPT_DIR/clio.sh"; then
        echo -e "${GREEN}Module update complete.${NC}"
    else
        echo -e "${RED}Module update failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Selene | Module update failed" >> "$ERROR_LOG"
    fi
}

# === Function: Clean Up System ===
cleanup_system() {
    echo -e "${GREEN}--- Cleaning up unused packages and caches ---${NC}"
    echo "$(date '+%F %T') | Selene | Cleanup started" >> "$AUDIT_LOG"

    if sudo apt-get -y autoremove && sudo apt-get -y autoclean; then
        echo -e "${GREEN}System cleanup complete.${NC}"
    else
        echo -e "${RED}System cleanup failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Selene | Cleanup failed" >> "$ERROR_LOG"
    fi
}

# === Function: Restart Services ===
restart_services() {
    echo -e "${GREEN}--- Restarting core services ---${NC}"
    echo "$(date '+%F %T') | Selene | Service restart started" >> "$AUDIT_LOG"

    if sudo systemctl restart nginx && sudo systemctl restart php8.4-fpm; then
        echo -e "${GREEN}Core services restarted.${NC}"
    else
        echo -e "${RED}Service restart failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Selene | Service restart failed" >> "$ERROR_LOG"
    fi
}

# === Function: Full Update Cycle ===
full_update_cycle() {
    echo -e "${YELLOW}=== Starting Full Update Cycle ===${NC}"
    update_os
    update_modules
    cleanup_system
    restart_services
    echo -e "${YELLOW}=== Full Update Cycle Complete ===${NC}"
}

# === Selene's own submenu ===
while true; do
    echo
    echo "=== Selene: Update Cycle ==="
    echo "1) Update OS packages"
    echo "2) Update Jessica modules (via Clio)"
    echo "3) Clean up system"
    echo "4) Restart core services"
    echo "5) Full update cycle (all of the above)"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) update_os ;;
        2) update_modules ;;
        3) cleanup_system ;;
        4) restart_services ;;
        5) full_update_cycle ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
