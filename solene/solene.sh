#!/bin/bash
#
# Solène - Environment-Aware Greeter & Desktop Manager
# If a GUI is detected, it manages KDE Plasma themes and wallpapers.
# If headless, it provides a seasonal MOTD greeting.

# --- Load Central Config ---
# This ensures all paths, colors, and settings are consistent.
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    # Fallback colors if dorian isn't present
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

# --- Main Logic: Detect Environment ---
# We check for the $DISPLAY variable, a standard way to see if a GUI is running.
if [[ -n "$DISPLAY" ]] && command -v plasma-apply-colorscheme &> /dev/null; then
    # --- GUI MODE (KDE Plasma Detected) ---
    # This block will only run on your Kubuntu desktop.

    # Get today's sunrise/sunset times and other data via a dedicated Python helper.
    # This keeps the main script clean while leveraging Python's powerful libraries.
    SUN_DATA=$(python3 "$HOME/jessica/solene/solene_helper.py")
    
    # Check if the Python script ran successfully
    if [[ -z "$SUN_DATA" ]]; then
        echo "Error: Could not retrieve sun data from helper script." >&2
        exit 1
    fi
    
    # Read the data into variables. The <<< operator feeds the string to the read command.
    read -r IS_DAY SEASONAL_GREETING DAILY_GREETING BOOT_GREETING WALLPAPER_PATH <<< "$SUN_DATA"

   

    if [[ "$IS_DAY" == "True" ]]; then
        FULL_GREETING="$BOOT_GREETING $SEASONAL_GREETING $DAILY_GREETING Amber, it’s your time to shine."
        plasma-apply-colorscheme "$AMBER_SCHEME"
        konsoleprofile "profile=$AMBER_PROFILE"
        plasma-apply-wallpaperimage "$WALLPAPER_PATH"
    else
        FULL_GREETING="$BOOT_GREETING $SEASONAL_GREETING $DAILY_GREETING Salacia, the night is yours to keep."
        plasma-apply-colorscheme "$SALACIA_SCHEME"
        konsoleprofile "profile=$SALACIA_PROFILE"
        plasma-apply-wallpaperimage "$WALLPAPER_PATH"
    fi
    
    echo -e "${YELLOW}Solène observes:${NC} '$FULL_GREETING'"

else
    # --- HEADLESS MODE (No GUI Detected) ---
    # This block will run on sentinel-star and your other servers.
    
    # Get greeting data from the Python helper script.
    GREETING_DATA=$(python3 "$HOME/jessica/solene/solene_helper.py" --headless)
    
    if [[ -n "$GREETING_DATA" ]]; then
        read -r SEASONAL_GREETING DAILY_GREETING BOOT_GREETING <<< "$GREETING_DATA"
        # The --boot flag should only be used when called by the MOTD system
        if [[ "$1" == "--boot" ]]; then
             echo -e "\n${YELLOW}Solène observes:${NC} '$BOOT_GREETING $SEASONAL_GREETING $DAILY_GREETING'\n"
        else
             echo -e "\n${YELLOW}Solène observes:${NC} '$SEASONAL_GREETING $DAILY_GREETING'\n"
        fi
    else
        echo "Error: Could not retrieve greeting data from helper script." >&2
    fi
fi

