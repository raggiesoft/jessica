#!/bin/bash
#
# Allison - Jessica Suite Man Page Installer
# This script installs the man pages for all Jessica Suite utilities.
#

# Source the dorian config to use the color codes for output
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    # Define fallback colors if dorian is not found
    GREEN='\033[0;32m'
    YELLOW='\033[1;32m'
    NC='\033[0m'
fi

# The standard directory for user-specific man pages
MAN_DIR="$HOME/.local/share/man/man1"
SOURCE_DIR="$HOME/jessica/paige/man"

echo -e "${YELLOW}--- Allison: Installing Jessica Suite Man Pages ---${NC}"

# 1. Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR: Source directory not found at $SOURCE_DIR${NC}"
    exit 1
fi

# 2. Create the target directory
echo "Ensuring man page directory exists at $MAN_DIR..."
mkdir -p "$MAN_DIR"

# 3. Copy all .1 files into the man directory
echo "Copying man pages..."
cp "$SOURCE_DIR"/*.1 "$MAN_DIR/"

# 4. Update the man database
echo "Updating man database... (This may take a moment)"
mandb

echo -e "${GREEN}--- Installation Complete! ---${NC}"
echo "You can now view help for any script, for example: man daphne"