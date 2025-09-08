#!/bin/bash
#
# Marina - Backup & Restore Module for Daphne
# Location: ~/jessica/clara/marina.sh
#
# DESCRIPTION:
#   Marina safeguards your Jessica/Clara environment by creating and restoring
#   backups of critical directories (sites, configs, logs, etc.).
#
#   She can:
#     - Create timestamped backups
#     - Restore from a selected backup
#     - List available backups
#     - Purge old backups beyond a retention limit
#
#   All paths, colors, and log locations are loaded from the central config (dorian).
#   Marina logs all actions to the AUDIT_LOG and any failures to the ERROR_LOG.

# === Load Central Config ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Defaults from Dorian ===
# LAVINIA_BACKUP_DIR and LAVINIA_LOG_DIR can be reused or define MARINA_BACKUP_DIR in Dorian
BACKUP_DIR="${MARINA_BACKUP_DIR:-$TOOL_HOME/clara/backups}"
RETENTION_DAYS="${MARINA_RETENTION_DAYS:-30}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# === Function: Create Backup ===
create_backup() {
    echo -e "${GREEN}--- Create Backup ---${NC}"
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/jessica_backup_$TIMESTAMP.tar.gz"

    echo "$(date '+%F %T') | Marina | Backup started: $BACKUP_FILE" >> "$AUDIT_LOG"

    # Example: backup sites and config (adjust as needed)
    if tar -czf "$BACKUP_FILE" "$SITE_BASE_DIR" "$TOOL_HOME/elise/dorian"; then
        echo -e "${GREEN}Backup created at $BACKUP_FILE${NC}"
    else
        echo -e "${RED}Backup failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Marina | Backup failed: $BACKUP_FILE" >> "$ERROR_LOG"
    fi
}

# === Function: List Backups ===
list_backups() {
    echo -e "${GREEN}--- Available Backups ---${NC}"
    ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found."
}

# === Function: Restore Backup ===
restore_backup() {
    echo -e "${GREEN}--- Restore Backup ---${NC}"
    list_backups
    echo
    read -rp "Enter full path to backup file to restore: " BACKUP_FILE
    [ ! -f "$BACKUP_FILE" ] && { echo -e "${RED}Backup file not found.${NC}"; return; }

    read -rp "This will overwrite current files. Continue? [y/N]: " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "Restore cancelled."; return; }

    echo "$(date '+%F %T') | Marina | Restore started: $BACKUP_FILE" >> "$AUDIT_LOG"

    if tar -xzf "$BACKUP_FILE" -C /; then
        echo -e "${GREEN}Restore complete.${NC}"
    else
        echo -e "${RED}Restore failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Marina | Restore failed: $BACKUP_FILE" >> "$ERROR_LOG"
    fi
}

# === Function: Purge Old Backups ===
purge_backups() {
    echo -e "${GREEN}--- Purge Old Backups ---${NC}"
    echo "Retention: $RETENTION_DAYS days"
    echo "$(date '+%F %T') | Marina | Purge started" >> "$AUDIT_LOG"

    if find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;; then
        echo -e "${GREEN}Old backups purged.${NC}"
    else
        echo -e "${RED}Purge failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Marina | Purge failed" >> "$ERROR_LOG"
    fi
}

# === Marina's own submenu ===
while true; do
    echo
    echo "=== Marina: Backup & Restore ==="
    echo "1) Create backup"
    echo "2) List backups"
    echo "3) Restore from backup"
    echo "4) Purge old backups"
    echo "0) Return to Daphne"
    read -rp "Choice: " choice
    case "$choice" in
        1) create_backup ;;
        2) list_backups ;;
        3) restore_backup ;;
        4) purge_backups ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
