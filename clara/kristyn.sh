#!/bin/bash
#
# Kristyn - Household Wellness & Crew Check-In
# Location: ~/jessica/clara/kristyn.sh
#
# DESCRIPTION:
#   Kristyn is Dorian's best friend, aide, and bridge between siblings.
#   She checks in on the crew, makes sure everyone is present and active,
#   and delivers a warm daily brief. She also logs "hug events" for fun.
#
#   All paths, colors, and log locations are loaded from the central config (dorian).
#   Logs are plain text (no ANSI codes) for clean reading in Vim/Nano/grep.

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

# === Function: Introduce the family ===
introduce_family() {
    echo -e "${GREEN}Hi, I’m Kristyn.${NC} I live here with my best friend Dorian — we share a room on the ground floor."
    echo "He’s the only brother in a house full of sisters, and we’re pretty much attached at the hip."
    echo "Let me introduce you to everyone:"
    echo "  • Jessica – our oldest sister and the house itself."
    echo "  • Aubrie – keeper of web pages."
    echo "  • Daphne – our coordinator."
    echo "  • Phoebe – the builder."
    echo "  • Selene – night-shift caretaker."
    echo "  • Clio – historian."
    echo "  • Marina – archivist."
    echo "  • Iris – watcher."
    echo "  • Thalia – tinkerer."
    echo "  • Helena – trickster-guardian."
    echo "  • Amanda – creative whirlwind."
    echo "And of course, Dorian – my best friend, the keeper of our shared memory."
}

# === Function: Check sibling scripts ===
check_siblings() {
    echo
    echo -e "${YELLOW}--- Crew Status Check ---${NC}"
    local siblings=("phoebe" "selene" "marina" "iris" "thalia" "clio" "helena" "amanda")
    for sib in "${siblings[@]}"; do
        local path="$SITE_MANAGER_DIR/$sib.sh"
        if [[ -x "$path" ]]; then
            echo -e "${GREEN}$sib.sh is present and executable.${NC}"
        else
            echo -e "${RED}$sib.sh is missing or not executable!${NC}"
        fi
    done
}

# === Function: Log a hug event ===
log_hug() {
    local TS
    TS="$(date '+%F %T')"
    local entry="$TS | Kristyn | Hugged Dorian (squeeze)"
    echo "$entry" | strip_colors >> "$AUDIT_LOG"
    echo "$entry" | strip_colors >> "$DEPLOYMENT_LOG"
    echo "$entry" | strip_colors >> "$SITE_BASE_DIR/hug_history.log"
    echo -e "${GREEN}Hug logged.${NC}"
}

# === Function: Daily brief ===
daily_brief() {
    echo
    echo -e "${YELLOW}--- Daily Brief ---${NC}"
    echo "Jessica’s systems are humming."
    echo "Everyone’s accounted for."
    echo "Remember to hydrate, stretch, and take breaks."
}

# === Kristyn's menu ===
while true; do
    echo
    echo "=== Kristyn: Household Wellness & Crew Check-In ==="
    echo "1) Introduce the family"
    echo "2) Check sibling scripts"
    echo "3) Log a hug for Dorian"
    echo "4) Daily brief"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) introduce_family ;;
        2) check_siblings ;;
        3) log_hug ;;
        4) daily_brief ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
