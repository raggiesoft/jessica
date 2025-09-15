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

# === Function: Emergency Plugin Disable ===
emergency_plugin_disable() {
    echo -e "${YELLOW}--- Emergency WordPress Plugin Disable ---${NC}"
    
    if [ ${#SERVERS[@]} -eq 0 ]; then
        echo -e "${RED}No remote servers defined in dorian config.${NC}"
        return
    fi

    echo "Select the server where the locked site is hosted:"
    local i=0
    for server_entry in "${SERVERS[@]}"; do
        menu_name=$(echo "$server_entry" | cut -d'|' -f1)
        echo "  $((i+1))) $menu_name"
        i=$((i+1))
    done
    echo "  0) Cancel"
    read -rp "Choice: " server_choice

    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 0 ] || [ "$server_choice" -gt ${#SERVERS[@]} ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return
    fi
    [ "$server_choice" -eq 0 ] && return

    server_info=${SERVERS[$((server_choice-1))]}
    ssh_target=$(echo "$server_info" | cut -d'|' -f2)
    remote_path=$(echo "$server_info" | cut -d'|' -f3)

    read -rp "Enter the domain of the WordPress site (e.g., blog.example.com): " domain
    [ -z "$domain" ] && { echo -e "${RED}Domain required.${NC}"; return; }

    echo -e "${YELLOW}Fetching list of active plugins from $domain...${NC}"
    remote_command="wp plugin list --status=active --path=$remote_path/$domain --format=csv --fields=name,title"
    mapfile -t plugins < <(ssh -T "$ssh_target" "$remote_command" | tail -n +2)

    if [ ${#plugins[@]} -eq 0 ]; then
        echo -e "${RED}Could not find any active plugins or connect to the site.${NC}"
        return
    fi

    echo "Select the plugin to deactivate:"
    local j=1
    for plugin_line in "${plugins[@]}"; do
        plugin_name=$(echo "$plugin_line" | cut -d',' -f1)
        plugin_title=$(echo "$plugin_line" | cut -d',' -f2)
        echo "  $j) $plugin_title ($plugin_name)"
        j=$((j+1))
    done
    echo "  0) Cancel"
    read -rp "Choice: " plugin_choice

    if ! [[ "$plugin_choice" =~ ^[0-9]+$ ]] || [ "$plugin_choice" -lt 0 ] || [ "$plugin_choice" -gt ${#plugins[@]} ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return
    fi
    [ "$plugin_choice" -eq 0 ] && return
    
    plugin_to_disable=$(echo "${plugins[$((plugin_choice-1))]}" | cut -d',' -f1)

    echo -e "${YELLOW}Attempting to deactivate '$plugin_to_disable'...${NC}"
    deactivate_command="wp plugin deactivate $plugin_to_disable --path=$remote_path/$domain"

    if ssh -T "$ssh_target" "$deactivate_command"; then
        echo -e "${GREEN}Plugin '$plugin_to_disable' deactivated successfully!${NC}"
        echo "You should now be able to access your admin dashboard."
    else
        echo -e "${RED}Failed to deactivate plugin.${NC}"
    fi
}

# === NEW Function: Nuke All Plugins ===
nuke_all_plugins() {
    echo -e "${RED}--- DANGER: Deactivate ALL WordPress Plugins ---${NC}"
    
    if [ ${#SERVERS[@]} -eq 0 ]; then
        echo -e "${RED}No remote servers defined in dorian config.${NC}"
        return
    fi

    echo "Select the server where the broken site is hosted:"
    local i=0
    for server_entry in "${SERVERS[@]}"; do
        menu_name=$(echo "$server_entry" | cut -d'|' -f1)
        echo "  $((i+1))) $menu_name"
        i=$((i+1))
    done
    echo "  0) Cancel"
    read -rp "Choice: " server_choice

    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 0 ] || [ "$server_choice" -gt ${#SERVERS[@]} ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return
    fi
    [ "$server_choice" -eq 0 ] && return

    server_info=${SERVERS[$((server_choice-1))]}
    ssh_target=$(echo "$server_info" | cut -d'|' -f2)
    remote_path=$(echo "$server_info" | cut -d'|' -f3)

    read -rp "Enter the domain of the WordPress site (e.g., blog.example.com): " domain
    [ -z "$domain" ] && { echo -e "${RED}Domain required.${NC}"; return; }

    echo
    echo -e "${YELLOW}WARNING: This will deactivate ALL plugins on '$domain'.${NC}"
    echo "This is the 'nuclear option' for when a site is completely broken."
    read -rp "To confirm, please type NUKE: " confirm

    if [ "$confirm" != "NUKE" ]; then
        echo "Confirmation failed. Aborting."
        return
    fi

    echo -e "${YELLOW}Attempting to deactivate all plugins...${NC}"
    deactivate_command="wp plugin deactivate --all --path=$remote_path/$domain"

    if ssh -T "$ssh_target" "$deactivate_command"; then
        echo -e "${GREEN}All plugins on '$domain' have been deactivated.${NC}"
        echo "You should now be able to access your admin dashboard to reactivate them one by one."
    else
        echo -e "${RED}Failed to deactivate plugins.${NC}"
    fi
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
    echo "4) Emergency WordPress Plugin Disable"
    echo "5) Emergency Nuke All Plugins (WordPress)" # <-- NEW
    echo "6) Show Jessica version"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) test_connectivity ;;
        2) show_ips ;;
        3) clear_nginx_cache ;;
        4) emergency_plugin_disable ;;
        5) nuke_all_plugins ;; # <-- NEW
        6) show_version ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done