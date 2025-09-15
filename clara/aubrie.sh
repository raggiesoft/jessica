#!/bin/bash
#
# Aubrie - Keeper of Web Pages & Seed Garden
# Location: ~/jessica/clara/aubrie.sh
#
# DESCRIPTION:
#   Aubrie manages the "seed garden" of website templates and application installers.
#   She can "plant" simple templates or run complex installers for applications
#   like WordPress, hardening them for security from the start.
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
# CLARA_DIR is defined in dorian, points to ~/jessica/clara
SEED_GARDEN_DIR="$TOOL_HOME/aubrie/seeds"
APP_INSTALLER_DIR="$CLARA_DIR/aubrie" # UPDATED LOCATION
mkdir -p "$SITE_BASE_DIR" "$SEED_GARDEN_DIR" "$APP_INSTALLER_DIR"

# === Utility Functions ===
pause() { read -rp "Press [Enter] key to continue..."; }

# NEW: Converts a script filename like 'wordpress-secure.sh' to 'Wordpress Secure'
get_friendly_name() {
    local filename="$1"
    # Remove .sh extension
    local base_name="${filename%.sh}"
    # Replace hyphens with spaces
    local spaced_name="${base_name//-/ }"
    # Capitalize each word
    local friendly_name=""
    for word in $spaced_name; do
        friendly_name+="${word^} "
    done
    # Remove trailing space and echo
    echo "${friendly_name% }"
}


# === Function: List available seeds (templates) ===
list_seeds() {
    echo -e "${GREEN}--- Available Website Seeds (Templates) ---${NC}"
    if [ -z "$(ls -A "$SEED_GARDEN_DIR")" ]; then
        echo "No seeds found in $SEED_GARDEN_DIR"
    else
        ls -1 "$SEED_GARDEN_DIR"
    fi
}

# === Function: List available application installers ===
list_app_installers() {
    echo -e "${GREEN}--- Available Web Applications ---${NC}"
    
    # Read script names into an indexed array
    mapfile -t installers < <(find "$APP_INSTALLER_DIR" -maxdepth 1 -type f -name "*.sh")

    if [ ${#installers[@]} -eq 0 ]; then
        echo "No application installers found in $APP_INSTALLER_DIR"
        return 1
    fi

    # Display a numbered menu with friendly names
    local i=1
    for installer_path in "${installers[@]}"; do
        local script_name
        script_name=$(basename "$installer_path")
        local friendly_name
        friendly_name=$(get_friendly_name "$script_name")
        echo "  $i) $friendly_name"
        i=$((i+1))
    done
    return 0
}

# === Function: Plant a new site from a seed ===
plant_seed() {
    echo -e "${GREEN}--- Plant a New Site from a Template ---${NC}"
    list_seeds
    echo
    read -rp "Enter the name of the seed to plant: " SEED_NAME
    [ -z "$SEED_NAME" ] && { echo -e "${RED}Seed name required.${NC}"; pause; return; }
    if [ ! -d "$SEED_GARDEN_DIR/$SEED_NAME" ]; then
        echo -e "${RED}Seed '$SEED_NAME' not found.${NC}"; pause; return;
    fi

    read -rp "Enter the destination folder name (e.g., my-new-site.com): " DEST_NAME
    [ -z "$DEST_NAME" ] && { echo -e "${RED}Destination folder name is required.${NC}"; pause; return; }

    DEST_PATH="$SITE_BASE_DIR/$DEST_NAME"
    if [ -d "$DEST_PATH" ]; then
        echo -e "${RED}Error: A directory already exists at $DEST_PATH${NC}"; pause; return;
    fi

    echo -e "${YELLOW}Planting '$SEED_NAME' at '$DEST_PATH'...${NC}"
    if cp -r "$SEED_GARDEN_DIR/$SEED_NAME" "$DEST_PATH"; then
        echo -e "${GREEN}Site planted successfully.${NC}"
        echo "$(date '+%F %T') | Aubrie | Planted seed '$SEED_NAME' to '$DEST_PATH'" >> "$AUDIT_LOG"
    else
        echo -e "${RED}Failed to plant seed.${NC}"
        echo "$(date '+%F %T') | ERROR | Aubrie | Failed to plant seed '$SEED_NAME' to '$DEST_PATH'" >> "$ERROR_LOG"
    fi
    pause
}

# === Function: Install a web application ===
install_application() {
    echo -e "${GREEN}--- Install a Web Application ---${NC}"
    
    # Read script names into an indexed array to match the menu
    mapfile -t installers < <(find "$APP_INSTALLER_DIR" -maxdepth 1 -type f -name "*.sh")
    
    list_app_installers || { pause; return; } # Call list function and check if it found any installers
    
    echo "  0) Cancel"
    read -rp "Choice: " choice

    # Validate that choice is a number and within range
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt ${#installers[@]} ]; then
        echo -e "${RED}Invalid choice.${NC}"; pause; return;
    fi
    
    [ "$choice" -eq 0 ] && return # Exit if user chose Cancel

    # Get the selected installer script from the array (adjust for 1-based index)
    local selected_installer=${installers[$((choice-1))]}

    # Execute the installer script
    bash "$selected_installer"
    pause
}

# === Aubrie's Menu ===
while true; do
    echo
    echo "=== Aubrie: Keeper of Web Pages ==="
    echo "1) Manage Template Seeds"
    echo "2) Install a Web Application"
    echo "0) Return to Daphne"
    read -rp "Choice: " main_choice

    case "$main_choice" in
        1) # Sub-menu for templates
            while true; do
                echo
                echo "--- Manage Template Seeds ---"
                echo "1) List available seeds"
                echo "2) Plant a new site from a seed"
                echo "0) Back to Aubrie"
                read -rp "Choice: " seed_choice
                case "$seed_choice" in
                    1) list_seeds; pause ;;
                    2) plant_seed ;;
                    0) break ;;
                    *) echo "Invalid choice." ;;
                esac
            done
            ;;
        2) install_application ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done