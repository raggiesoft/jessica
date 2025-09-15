#!/bin/bash
#
# Helena - Honeypot & Router Rotation Module for Daphne
# Location: ~/jessica/clara/helena.sh
#
# DESCRIPTION:
#   Helena is the decoy architect of the Clara ecosystem.
#   She handles:
#     - Deploying honeypot routers to mislead automated scans
#     - Rotating active router/public/private names to new safe names
#   Rotation always follows the "two girls and a guy" rule:
#     - Exactly two female names and one male name
#     - Roles (public folder, private folder, router file) are assigned randomly
#
#   All paths, colors, and log locations are loaded from the central config (dorian).
#   Helena logs her actions to the AUDIT_LOG, DEPLOYMENT_LOG, and per-site rotation_history.log.
#   Logs are plain text (no ANSI codes) for clean reading in Vim/Nano/grep.
#   Terminal output remains colorful for interactive use.

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Helper: Strip ANSI color codes for clean logging ===
strip_colors() {
    sed 's/\x1B

\[[0-9;]*[JKmsu]//g'
}

# === Function: Deploy Honeypot ===
deploy_honeypot() {
    echo -e "${GREEN}--- Deploying Honeypot ---${NC}"
    echo "$(date '+%F %T') | Helena | Honeypot deployment started" | strip_colors >> "$AUDIT_LOG"

    HONEYPOT_DIR="$SITE_BASE_DIR/honeypot_$(date +%s)"
    mkdir -p "$HONEYPOT_DIR"
    echo "<?php http_response_code(403); exit; ?>" > "$HONEYPOT_DIR/index.php"

    if [[ -f "$HONEYPOT_DIR/index.php" ]]; then
        echo -e "${GREEN}Honeypot deployed at $HONEYPOT_DIR${NC}"
    else
        echo -e "${RED}Honeypot deployment failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Helena | Honeypot deployment failed" | strip_colors >> "$ERROR_LOG"
    fi
}

# === Function: Rotate Router ===
rotate_router() {
    echo -e "${GREEN}--- Rotate Router ---${NC}"
    read -rp "Enter domain to rotate: " DOMAIN
    [ -z "$DOMAIN" ] && { echo -e "${RED}Domain required.${NC}"; return; }

    NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
    [ ! -f "$NGINX_CONF" ] && { echo -e "${RED}Nginx config not found for $DOMAIN${NC}"; return; }

    # Extract current values
    SITE_PATH=$(grep -Po '(?<=root\s)[^;]+' "$NGINX_CONF" | sed "s|/$ROUTER_FOLDER||")
    CURRENT_ROUTER_FOLDER=$(grep -Po '(?<=root\s)[^;]+' "$NGINX_CONF" | awk -F/ '{print $NF}')
    CURRENT_ROUTER_FILE=$(grep -Po '(?<=index\s)[^;]+' "$NGINX_CONF")

    echo -e "Current router folder: ${YELLOW}$CURRENT_ROUTER_FOLDER${NC}"
    echo -e "Current router file:   ${YELLOW}$CURRENT_ROUTER_FILE${NC}"

    # Generate two female and one male name
    FEMALE1=$(bash "$CORALIE" --sanitize-before --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
    FEMALE2=$(bash "$CORALIE" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
    MALE=$(bash "$CORALIE" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender male)

    # Shuffle and assign roles
    NAMES=("$FEMALE1" "$FEMALE2" "$MALE")
    mapfile -t SHUFFLED < <(shuf -e "${NAMES[@]}")
    NEW_PUBLIC_FOLDER="${SHUFFLED[0]}"
    NEW_PRIVATE_FOLDER="${SHUFFLED[1]}"
    NEW_ROUTER_FILE="${SHUFFLED[2]}${ROUTER_FILE_EXTENSION}"

    echo -e "New public folder:  ${GREEN}$NEW_PUBLIC_FOLDER${NC}"
    echo -e "New private folder: ${GREEN}$NEW_PRIVATE_FOLDER${NC}"
    echo -e "New router file:    ${GREEN}$NEW_ROUTER_FILE${NC}"

    # Create new structure
    mkdir -p "$SITE_PATH/$NEW_PUBLIC_FOLDER" "$SITE_PATH/$NEW_PRIVATE_FOLDER"
    cp -r "$SITE_PATH/$CURRENT_ROUTER_FOLDER"/* "$SITE_PATH/$NEW_PUBLIC_FOLDER/" 2>/dev/null || true
    cp "$SITE_PATH/$CURRENT_ROUTER_FOLDER/$CURRENT_ROUTER_FILE" "$SITE_PATH/$NEW_PUBLIC_FOLDER/$NEW_ROUTER_FILE"

    # Update Nginx config
    sed -i "s|$CURRENT_ROUTER_FOLDER|$NEW_PUBLIC_FOLDER|g" "$NGINX_CONF"
    sed -i "s|$CURRENT_ROUTER_FILE|$NEW_ROUTER_FILE|g" "$NGINX_CONF"

    # Deploy honeypot in old public folder
    echo "<?php http_response_code(403); exit; ?>" > "$SITE_PATH/$CURRENT_ROUTER_FOLDER/index.php"

    # Test and reload Nginx
    if sudo nginx -t && sudo systemctl reload nginx; then
        echo -e "${GREEN}Router rotation complete.${NC}"

        TS="$(date '+%F %T')"
        LOG_ENTRY="$TS | ROTATE | $DOMAIN | OLD: pub=$CURRENT_ROUTER_FOLDER, router=$CURRENT_ROUTER_FILE | NEW: pub=$NEW_PUBLIC_FOLDER, priv=$NEW_PRIVATE_FOLDER, router=$NEW_ROUTER_FILE"

        # Central logs
        echo "$LOG_ENTRY" | strip_colors >> "$DEPLOYMENT_LOG"
        echo "$TS | Helena | Router rotation complete for $DOMAIN | OLD: pub=$CURRENT_ROUTER_FOLDER, router=$CURRENT_ROUTER_FILE | NEW: pub=$NEW_PUBLIC_FOLDER, priv=$NEW_PRIVATE_FOLDER, router=$NEW_ROUTER_FILE" | strip_colors >> "$AUDIT_LOG"

        # Per-site rotation history
        SITE_HISTORY_FILE="$SITE_PATH/rotation_history.log"
        echo "$LOG_ENTRY" | strip_colors >> "$SITE_HISTORY_FILE"

        # Post-rotation briefing
        echo
        echo -e "${YELLOW}=== Manual Step Required ===${NC}"
        echo "1. Open the new router file in VS Code:"
        echo "     $SITE_PATH/$NEW_PUBLIC_FOLDER/$NEW_ROUTER_FILE"
        echo "2. Inside that file, update any hard-coded path to point to the new private folder:"
        echo "     $NEW_PRIVATE_FOLDER"
        echo "3. Save the file and test the site in your browser."
        echo
        echo -e "${YELLOW}=== Name Summary (Two Girls and a Guy) ===${NC}"
        echo "Public folder:  $NEW_PUBLIC_FOLDER"
        echo "Private folder: $NEW_PRIVATE_FOLDER"
        echo "Router file:    $NEW_ROUTER_FILE"
        echo
        echo "Remember: exactly two of these are female names, one is male — roles are randomized."
        echo
        echo "Per-site rotation history saved to: $SITE_HISTORY_FILE"

        # Show last 5 rotations for this site
        echo
        echo -e "${GREEN}--- Last 5 Rotations for $DOMAIN ---${NC}"
        tail -n 5 "$SITE_HISTORY_FILE"
    else
        echo -e "${RED}Nginx reload failed — reverting changes.${NC}"
        sed -i "s|$NEW_PUBLIC_FOLDER|$CURRENT_ROUTER_FOLDER|g" "$NGINX_CONF"
        sed -i "s|$NEW_ROUTER_FILE|$CURRENT_ROUTER_FILE|g" "$NGINX_CONF"
        echo "$(date '+%F %T') | ERROR | Helena | Router rotation failed for $DOMAIN" | strip_colors >> "$ERROR_LOG"
    fi
}

# === Helena's own submenu ===
while true; do
    echo
    echo "=== Helena: Honeypot & Router Rotation ==="
    echo "1) Deploy honeypot"
    echo "2) Rotate router"
    echo "3) Deploy honeypot and rotate router"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) deploy_honeypot ;;
        2) rotate_router ;;
        3)