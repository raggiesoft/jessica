#!/bin/bash
#
# Amanda - Modular Site Generator Menu
# Author: Michael + Copilot Labs
# Date: $(date +%F)
#
# DESCRIPTION:
#   Amanda is the interactive menu for creating, destroying, and managing sites
#   on the glowing-galaxy server. She delegates actual site creation/destruction
#   to the Site Manager script (Verity or site-manager.sh) and uses Coralie for
#   generating safe, sanitized folder/file names.
#
#   All configurable values (paths, colors, defaults, logs, etc.) are loaded
#   from the central config file "dorian" inside a female-named folder under ~/jessica.
#   This ensures every module in the suite shares the same settings.
#

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === First-Run Experience Marker ===
FIRST_RUN_MARKER="$TOOL_HOME/.first_run_complete"

# === Utility: Pause for user input ===
pause() { read -rp "Press [Enter] key to continue..."; }

# === Utility: Menu Header ===
menu_header() {
    clear
    echo -e "${YELLOW}=========================================${NC}"
    echo -e "   $MAIN_MENU_NAME — Site Generator Menu"
    echo -e "${YELLOW}=========================================${NC}"
    echo
    python3 "$SOLENE_DIR/solene.py"
}

# === First-Run: Firewall Setup ===
# Configures firewalls on the bastion host and all remote servers.
setup_firewalls() {
    echo
    echo -e "${YELLOW}--- Initial Firewall Configuration ---${NC}"

    # 1. Configure Bastion Host (sentinel-star)
    echo "Configuring firewall for the bastion host (sentinel-star)..."
    echo "This will allow SSH connections only."
    read -rp "Continue? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo ufw allow OpenSSH
        sudo ufw enable
        sudo ufw status
        echo -e "${GREEN}Bastion host firewall configured.${NC}"
    else
        echo -e "${RED}Skipping bastion host firewall setup.${NC}"
    fi
    echo

    # 2. Configure Remote Web Servers
    echo "Now, I will configure the firewalls on your remote web servers."
    echo "This will allow SSH, HTTP, and HTTPS traffic."
    if [ ${#SERVERS[@]} -eq 0 ]; then
        echo -e "${RED}No remote servers are defined in your dorian config. Skipping.${NC}"
    else
        for server_entry in "${SERVERS[@]}"; do
            menu_name=$(echo "$server_entry" | cut -d'|' -f1)
            ssh_target=$(echo "$server_entry" | cut -d'|' -f2)
            
            echo "Configuring firewall for ${YELLOW}$menu_name${NC} ($ssh_target)..."
            read -rp "Continue? [y/N]: " remote_confirm
            if [[ "$remote_confirm" =~ ^[Yy]$ ]]; then
                # SSH into the remote server and run the commands
                ssh -T "$ssh_target" <<EOF
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable
EOF
                echo -e "${GREEN}Firewall configured for $menu_name.${NC}"
            else
                echo -e "${RED}Skipping firewall setup for $menu_name.${NC}"
            fi
            echo
        done
    fi
}

# === First-Run "Out of Box Experience" ===
first_run_experience() {
    clear
    echo -e "${GREEN}Welcome to the Jessica Suite.${NC}"
    echo "It looks like this is your first time running the system."
    echo "We'll start by setting up your server firewalls for security."
    pause

    # Run the new firewall setup function
    setup_firewalls
    
    echo
    echo "Next, let's get you acquainted with the crew."
    pause
    
    clear
    echo -e "${GREEN}Hi, I’m Kristyn.${NC} I live here with my best friend Dorian..."
    echo "(Introduction text follows...)"
    # (Full introduction text from previous version would go here)

    # Create the marker file so this doesn't run again
    touch "$FIRST_RUN_MARKER"
    echo
    echo "Setup complete. You will now be taken to the main menu."
    pause
}

# === Option 1: Create a New Site ===
create_site() {
    echo -e "${GREEN}-- Create a New Site --${NC}"
    read -rp "Enter domain (e.g., example.com or status.example.com): " DOMAIN_NAME
    [ -z "$DOMAIN_NAME" ] && { echo -e "${RED}Domain is required.${NC}"; pause; return; }

    echo -e "${YELLOW}Generating sanitized stealth names via Coralie...${NC}"
    NAMEGEN_CMD="$NAMEGEN_DIR/coralie.sh"
    MALE_NAME=$(bash "$NAMEGEN_CMD" --sanitize-before --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender male)
    FEMALE1_NAME=$(bash "$NAMEGEN_CMD" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
    FEMALE2_NAME=$(bash "$NAMEGEN_CMD" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)

    if (( RANDOM % 2 )); then
        ROUTER_FOLDER="$FEMALE1_NAME"
        APP_FOLDER="$MALE_NAME"
        ROUTER_FILE="${FEMALE2_NAME}${ROUTER_FILE_EXTENSION}"
    else
        ROUTER_FOLDER="$FEMALE1_NAME"
        APP_FOLDER="$FEMALE2_NAME"
        ROUTER_FILE="${MALE_NAME}${ROUTER_FILE_EXTENSION}"
    fi

    echo -e "Router folder: ${GREEN}$ROUTER_FOLDER${NC}"
    echo -e "App folder:    ${GREEN}$APP_FOLDER${NC}"
    echo -e "Router file:   ${GREEN}$ROUTER_FILE${NC}"

    echo "$(date '+%F %T') | CREATE | $DOMAIN_NAME | router_dir=$ROUTER_FOLDER | app_dir=$APP_FOLDER | router_file=$ROUTER_FILE" >> "$DEPLOYMENT_LOG"
    echo "$(date '+%F %T') | Amanda | Site creation triggered for $DOMAIN_NAME" >> "$AUDIT_LOG"

    if bash "$SITE_MANAGER_SCRIPT" create \
        --domain "$DOMAIN_NAME" \
        --router-dir "$ROUTER_FOLDER" \
        --app-dir "$APP_FOLDER" \
        --router-file "$ROUTER_FILE" \
        --email "$CERT_EMAIL"; then
        echo -e "${GREEN}Site created successfully.${NC}"
    else
        echo -e "${RED}Site creation failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Amanda | Site creation failed for $DOMAIN_NAME" >> "$ERROR_LOG"
    fi
    pause
}

# (Other functions like destroy_site, rotate_router, generate_name remain the same)
# ...

# === Script Entry Point ===

# 1. Run the first-run experience if the marker file doesn't exist
if [ ! -f "$FIRST_RUN_MARKER" ]; then
    first_run_experience
fi

# 2. Start the main menu loop
while true; do
    menu_header
    echo "1. Create new site"
    echo "2. Destroy site"
    echo "3. Rotate router and deploy honeypot"
    echo "4. Generate random name"
    echo "5. Exit"
    echo
    read -rp "Enter choice [1-5]: " choice

    case "$choice" in
        1) create_site ;;
        2) destroy_site ;;
        3) rotate_router ;;
        4) generate_name ;;
        5) echo "Goodbye from $MAIN_MENU_NAME."; break ;;
        *) echo -e "${RED}Invalid option.${NC}"; pause ;;
    esac
done