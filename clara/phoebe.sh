#!/bin/bash
#
# Phoebe - Site creation & management module for Daphne
# Location: ~/jessica/clara/phoebe.sh
#
# DESCRIPTION:
#   Phoebe is the builder in the Clara ecosystem. Daphne calls her when the user
#   selects "Site creation & management" from the main menu.
#
#   She handles:
#     - Creating new sites (PHP or ASP.NET)
#     - Destroying existing sites
#   All configurable values (paths, colors, defaults, logs, etc.) are loaded
#   from the central config file "dorian" inside a female-named folder under ~/jessica.
#
#   Phoebe uses Coralie (with Lavinia pre-clean) to generate safe, sanitized
#   folder and file names for site deployment. She also integrates with Nginx,
#   Certbot, and systemd for full site provisioning.

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Function: Create a New Site ===
# Prompts for site details, generates safe names, writes Nginx/systemd configs,
# and issues SSL certificates.
create_site() {
    echo -e "${GREEN}--- Create a New Site ---${NC}"

    # Prompt for the domain/subdomain (site name)
    read -rp "Enter site name (e.g., michaelpragsdale.com or status.michaelpragsdale.com): " SITE_NAME
    [ -z "$SITE_NAME" ] && { echo -e "${RED}Site name required.${NC}"; return; }

    # Prompt for site type and normalize shorthand
    read -rp "Site type [PHP/ASP.NET]: " SITE_TYPE
    if [[ "$SITE_TYPE" =~ ^ASP$ ]]; then
        SITE_TYPE="ASP.NET"
    fi
    if [[ ! "$SITE_TYPE" =~ ^(PHP|ASP\.NET)$ ]]; then
        echo -e "${RED}Invalid type. Please enter PHP or ASP.NET.${NC}"
        return
    fi

    # Use global CERT_EMAIL from Dorian
    EMAIL="$CERT_EMAIL"

    # Generate safe folder/file names via Coralie with Lavinia pre-clean
    echo -e "${YELLOW}Pulling sanitized stealth names from Coralie...${NC}"
    ROUTER_FOLDER=$(bash "$CORALIE" --sanitize-before --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
    APP_FOLDER=$(bash "$CORALIE" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
    ROUTER_FILE="$(bash "$CORALIE" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender male)${ROUTER_FILE_EXTENSION}"

    SITE_PATH="$SITE_BASE_DIR/$SITE_NAME"

    # Show generated names
    echo -e "Router folder: ${GREEN}$ROUTER_FOLDER${NC}"
    echo -e "App folder:    ${GREEN}$APP_FOLDER${NC}"
    echo -e "Router file:   ${GREEN}$ROUTER_FILE${NC}"

    # Create directory structure
    mkdir -p "$SITE_PATH/$ROUTER_FOLDER" "$SITE_PATH/$APP_FOLDER"

    if [ "$SITE_TYPE" == "PHP" ]; then
        # Write Nginx config for PHP site
        sudo tee /etc/nginx/sites-available/$SITE_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name $SITE_NAME;
    root $SITE_PATH/$ROUTER_FOLDER;
    index $ROUTER_FILE;
    location / {
        try_files \$uri \$uri/ /$ROUTER_FILE?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
}
EOF
        # Create placeholder router file
        touch "$SITE_PATH/$ROUTER_FOLDER/$ROUTER_FILE"

    elif [ "$SITE_TYPE" == "ASP.NET" ]; then
        # Prompt for ASP.NET specifics
        read -rp "Enter internal app port [default: $ASP_PORT_DEFAULT]: " APP_PORT
        APP_PORT=${APP_PORT:-$ASP_PORT_DEFAULT}
        read -rp "Enter ASP.NET app name (without .dll): " APP_NAME

        DLL_PATH="$SITE_PATH/$APP_FOLDER/${APP_NAME}.dll"
        if [ ! -f "$DLL_PATH" ]; then
            echo -e "${RED}ERROR:${NC} Expected DLL not found at: $DLL_PATH"
            echo "Make sure you've published your ASP.NET app to that folder before running Phoebe."
            return
        fi

        # Write Nginx config for ASP.NET site
        sudo tee /etc/nginx/sites-available/$SITE_NAME > /dev/null <<EOF
upstream ${SITE_NAME}_upstream { server 127.0.0.1:$APP_PORT; }
server {
    listen 80;
    server_name $SITE_NAME;
    location / {
        proxy_pass http://${SITE_NAME}_upstream;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        # Create systemd service for ASP.NET app
        sudo tee /etc/systemd/system/kestrel-${SITE_NAME}.service > /dev/null <<EOF
[Unit]
Description=$APP_NAME ASP.NET Core Application
[Service]
WorkingDirectory=$SITE_PATH/$APP_FOLDER
ExecStart=/usr/bin/dotnet $DLL_PATH --urls "http://localhost:$APP_PORT"
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=${APP_NAME}
User=${SUDO_USER}
Environment=ASPNETCORE_ENVIRONMENT=$ASP_ENVIRONMENT
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable kestrel-${SITE_NAME}.service
        sudo systemctl start kestrel-${SITE_NAME}.service
    fi

    # Enable site and reload Nginx
    sudo ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl restart nginx

    # Issue SSL certificate
    sudo certbot --nginx --redirect --agree-tos -m "$EMAIL" -d "$SITE_NAME" --no-eff-email
    echo -e "${GREEN}Site $SITE_NAME created successfully!${NC}"
}

# === Function: Destroy a Site ===
# Removes Nginx config, SSL cert, systemd service (if any), and optionally deletes site files.
destroy_site() {
    echo -e "${GREEN}--- Destroy a Site ---${NC}"
    read -rp "Enter site name to destroy: " SITE_NAME
    [ -z "$SITE_NAME" ] && { echo -e "${RED}Site name required.${NC}"; return; }

    sudo rm -f /etc/nginx/sites-enabled/$SITE_NAME /etc/nginx/sites-available/$SITE_NAME
    sudo nginx -t && sudo systemctl restart nginx
    sudo certbot delete --cert-name "$SITE_NAME"

    if [ -f "/etc/systemd/system/kestrel-${SITE_NAME}.service" ]; then
        sudo systemctl stop kestrel-${SITE_NAME}.service
        sudo systemctl disable kestrel-${SITE_NAME}.service
        sudo rm /etc/systemd/system/kestrel-${SITE_NAME}.service
        sudo systemctl daemon-reload
    fi

    read -rp "Delete web/app directory under $SITE_BASE_DIR? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && sudo rm -rf "$SITE_BASE_DIR/$SITE_NAME"

    echo -e "${GREEN}Site $SITE_NAME destroyed.${NC}"
}

# === Phoebe's own submenu ===
# Loops until the user chooses to return to Daphne.
while true; do
    echo
    echo "=== Phoebe: Site Management ==="
    echo "1) Create site"
    echo "2) Destroy site"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) create_site ;;
        2) destroy_site ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
