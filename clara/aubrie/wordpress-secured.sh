#!/bin/bash
#
# Aubrie's Installer Seed: WordPress (Secured)
#
# DESCRIPTION:
#   This script installs the latest version of WordPress with critical security
#   obfuscations and a recommended set of starter plugins. It will automatically
#   install WP-CLI if it is not already present.
#
#   All paths and colors are loaded from the central config (dorian).

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo -e "\033[0;31mConfig file not found at $CONFIG_FILE\033[0m" >&2
    exit 1
fi

# === Function: Install WP-CLI if not present ===
install_wp_cli() {
    echo -e "${YELLOW}WP-CLI not found. Attempting to install...${NC}"
    echo "This will require sudo password for the final step."
    
    # Download the Phar file
    if ! curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; then
        echo -e "${RED}Failed to download wp-cli.phar. Please install manually.${NC}"
        return 1
    fi
    
    # Make it executable
    chmod +x wp-cli.phar
    
    # Move it into the PATH
    if sudo mv wp-cli.phar /usr/local/bin/wp; then
        echo -e "${GREEN}WP-CLI installed successfully to /usr/local/bin/wp${NC}"
    else
        echo -e "${RED}Failed to move wp-cli.phar to /usr/local/bin/. Sudo permissions may be required.${NC}"
        return 1
    fi
}

# === Dependency Check ===
if ! command -v wp &> /dev/null; then
    install_wp_cli || exit 1
fi

# === Main Installer Logic ===
echo -e "${GREEN}--- Aubrie: Secure WordPress Installer ---${NC}"

# --- 1. Gather Information ---
read -rp "Enter the domain for the new WordPress site (e.g., blog.example.com): " DOMAIN_NAME
[ -z "$DOMAIN_NAME" ] && { echo -e "${RED}Domain name is required.${NC}"; return; }

read -rp "Enter the MySQL database name: " DB_NAME
read -rp "Enter the MySQL database user: " DB_USER
read -sp "Enter the MySQL database password: " DB_PASS
echo

SITE_ROOT="$SITE_BASE_DIR/$DOMAIN_NAME"
if [ -d "$SITE_ROOT" ]; then
    echo -e "${RED}Error: A directory already exists at $SITE_ROOT${NC}"
    return
fi

# --- 2. Generate Secure Names via Coralie ---
echo -e "${YELLOW}Generating secure, random names via Coralie...${NC}"
PUBLIC_ROUTER_DIR=$(bash "$CORALIE_SCRIPT" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female)
SECURE_LOGIN_FILE="$(bash "$CORALIE_SCRIPT" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender female).php"
PRIVATE_APP_DIR=$(bash "$CORALIE_SCRIPT" --mode "$CORALIE_MODE" --case "$CORALIE_CASE" --type first --gender male)

# --- 3. Download and Prepare WordPress ---
echo -e "${YELLOW}Downloading the latest version of WordPress...${NC}"
WP_PATH="$SITE_ROOT/$PRIVATE_APP_DIR"
mkdir -p "$WP_PATH"
# Use wp-cli to download, more reliable
sudo -u www-data wp core download --path="$WP_PATH"

# --- 4. Obfuscate and Harden ---
echo -e "${YELLOW}Hardening the installation...${NC}"
# Create the public directory
mkdir -p "$SITE_ROOT/$PUBLIC_ROUTER_DIR"
# Move the index.php to become our secure router
mv "$WP_PATH/index.php" "$SITE_ROOT/$PUBLIC_ROUTER_DIR/index.php"
# Create our secure login file
mv "$WP_PATH/wp-login.php" "$SITE_ROOT/$PUBLIC_ROUTER_DIR/$SECURE_LOGIN_FILE"

# Update the secure router to point to the correct private directory
sed -i "s#wp-blog-header.php#../$PRIVATE_APP_DIR/wp-blog-header.php#" "$SITE_ROOT/$PUBLIC_ROUTER_DIR/index.php"

# --- 5. Configure WordPress ---
echo -e "${YELLOW}Creating wp-config.php...${NC}"
sudo -u www-data wp config create \
    --path="$WP_PATH" \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --extra-php <<PHP
define( 'WP_HOME', 'https://' . \$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'https://' . \$_SERVER['HTTP_HOST'] . '/$PRIVATE_APP_DIR' );
define( 'WP_CONTENT_URL', 'https://' . \$_SERVER['HTTP_HOST'] . '/$PRIVATE_APP_DIR/wp-content' );
PHP

# --- 6. Install Recommended Plugins ---
echo -e "${YELLOW}Installing recommended plugins via WP-CLI...${NC}"
PLUGINS="wordfence wp-dark-mode wordpress-seo w3-total-cache contact-form-7 updraftplus"
if sudo -u www-data wp plugin install $PLUGINS --activate --path="$WP_PATH"; then
    echo -e "${GREEN}Starter plugins installed successfully.${NC}"
else
    echo -e "${RED}Warning: Failed to install one or more plugins.${NC}"
fi


# --- 7. Final Instructions for Phoebe ---
echo
echo -e "${GREEN}--- WordPress Installation Prepared! ---${NC}"
echo "Aubrie has securely prepared the files. The next step is to run Phoebe to configure the server."
echo
echo -e "${YELLOW}=== Information for Phoebe ===${NC}"
echo "When Phoebe asks for the site details, use the following:"
echo
echo -e "  - ${CYAN}Domain Name:${NC} $DOMAIN_NAME"
echo -e "  - ${CYAN}Site Type:${NC} PHP"
echo -e "  - ${CYAN}Router (Public) Directory:${NC} $PUBLIC_ROUTER_DIR"
echo -e "  - ${CYAN}Application (Private) Directory:${NC} (This is not needed for Phoebe's PHP setup)"
echo -e "  - ${CYAN}Router File:${NC} index.php"
echo
echo -e "${YELLOW}Your secure, unique login URL will be:${NC}"
echo -e "  ${GREEN}https://$DOMAIN_NAME/$SECURE_LOGIN_FILE${NC}"
echo
echo -e "${YELLOW}IMPORTANT:${NC} If you have a license for a paid plugin like 'WP Dark Mode Ultimate', you will need to install it manually from the WordPress admin dashboard according to the author's instructions after Phoebe is finished."
echo
echo "Remember to visit the main URL to complete the WordPress setup process after Phoebe is finished."
echo "$(date '+%F %T') | Aubrie | Prepared secure WordPress install for '$DOMAIN_NAME'" >> "$AUDIT_LOG"