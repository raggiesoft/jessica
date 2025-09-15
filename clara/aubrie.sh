#!/bin/bash
#
# Aubrie - Keeper of Web Pages & Seed Garden
# Location: ~/jessica/clara/aubrie.sh
#
# DESCRIPTION:
#   Aubrie serves as the main menu for planting website templates and running
#   application installers. Each installer is a self-contained script paired
#   with a directory of assets (plugins, themes, .sql files, etc.).
#
#   All paths and colors are loaded from the central config (dorian).

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Aubrie's Specific Paths ===
# This is now the single source for all of Aubrie's installers.
INSTALLER_DIR="$CLARA_DIR/aubrie"
mkdir -p "$INSTALLER_DIR"

# === Utility Functions ===
pause() { read -rp "Press [Enter] key to continue..."; }

# Converts a script filename like 'wordpress-secured.sh' to 'Wordpress Secured'
get_friendly_name() {
    local filename="$1"
    local base_name="${filename%.sh}"
    local spaced_name="${base_name//-/ }"
    local friendly_name=""
    for word in $spaced_name; do
        friendly_name+="${word^} "
    done
    echo "${friendly_name% }"
}

# === Aubrie's Main Menu ===
while true; do
    echo
    echo "=== Aubrie: The Seed Garden ==="
    
    # Read installer scripts into an indexed array
    mapfile -t installers < <(find "$INSTALLER_DIR" -maxdepth 1 -type f -name "*.sh")

    if [ ${#installers[@]} -eq 0 ]; then
        echo "No installers found in $INSTALLER_DIR"
        echo "Create a script (e.g., 'my-template.sh') to get started."
        pause
        break
    fi

    # Display a dynamic, numbered menu with friendly names
    local i=1
    for installer_path in "${installers[@]}"; do
        local script_name
        script_name=$(basename "$installer_path")
        local friendly_name
        friendly_name=$(get_friendly_name "$script_name")
        echo "  $i) Plant '$friendly_name'"
        i=$((i+1))
    done
    echo "  0) Return to Daphne"
    read -rp "Choice: " choice

    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt ${#installers[@]} ]; then
        echo -e "${RED}Invalid choice.${NC}"; continue;
    fi
    
    [ "$choice" -eq 0 ] && break

    # Get the selected installer script from the array
    local selected_installer=${installers[$((choice-1))]}

    # Execute the selected installer
    bash "$selected_installer"
    pause
done