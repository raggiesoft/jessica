#!/bin/bash
#
# Thalia - Utilities Module for Daphne
# Location: ~/jessica/clara/thalia.sh
#
# DESCRIPTION:
#   Thalia is the "miscellaneous toolbox" of the Clara ecosystem.
#   She provides small, handy utilities that don't fit neatly into the other
#   specialist modules, but are still valuable for day-to-day operations.
#
#   Examples:
#     - Test connectivity to a domain
#     - Show server IP addresses
#     - Clear Nginx cache
#     - Generate a quick random safe name via Coralie
#     - Display Jessica's current version (from Git)
#
#   All paths, colors, and defaults are loaded from the central config (dorian).

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Function: Test connectivity to a domain ===
test_connectivity() {
    read -rp "Enter domain to test: " domain
    [ -z "$domain" ] && { echo -e "${RED}Domain required.${NC}"; return; }
    echo -e "${GREEN}Pinging $domain...${NC}"
    ping -c 4 "$domain"
}

# === Function: Show server IP addresses ===
show_ips() {
    echo -e "${GREEN}--- Server IP Addresses ---${NC}"
    ip addr show | awk '/inet / {print $2, $NF}'
}

# === Function: Clear Nginx cache ===
clear_nginx_cache() {
    CACHE_DIR="/var/cache/nginx"
    echo -e "${YELLOW}Clearing Nginx cache at $CACHE_DIR...${NC}"
    sudo rm -rf "$CACHE_DIR"/*
    echo -e "${GREEN}Nginx cache cleared.${NC}"
}

# === Function: Generate a quick random safe name via Coralie ===
quick_name() {
    echo -e "${GREEN}--- Generating safe name via Coralie ---${NC}"
    bash "$NAMEGEN_DIR/coralie.sh" --sanitize-before --mode "$CORALIE_MODE" --case proper --type first --gender auto
}

# === Function: Show Jessica's current version (Git) ===
show_version() {
    echo -e "${GREEN}--- Jessica Version ---${NC}"
    if [[ -d "$TOOL_HOME/.git" ]]; then
        git -C "$TOOL_HOME" log -1 --pretty=format:"%h - %s (%ci)"
        echo
    else
        echo -e "${RED}Not a Git repository.${NC}"
    fi
}

# === Thalia's own submenu ===
while true; do
    echo
    echo "=== Thalia: Utilities ==="
    echo "1) Test connectivity to a domain"
    echo "2) Show server IP addresses"
    echo "3) Clear Nginx cache"
    echo "4) Generate quick safe name"
    echo "5) Show Jessica version"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) test_connectivity ;;
        2) show_ips ;;
        3) clear_nginx_cache ;;
        4) quick_name ;;
        5) show_version ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
