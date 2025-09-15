#!/bin/bash
# Lavinia - Name Sanitizer for Junia
# Modes:
#   --dry-run        : Preview removals, no changes.
#   (no flag)        : Live sanitization, with backups.
#   --restore        : Restore most recent backup.
#   --delete-backups : Permanently remove all backups.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDE_FILE="$SCRIPT_DIR/.exclude_names.txt"
LOG_DIR="$SCRIPT_DIR/logs"
BACKUP_ROOT="$SCRIPT_DIR/backups"
MODE="sanitize"
DRY_RUN=false

mkdir -p "$LOG_DIR" "$BACKUP_ROOT"
TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/lavinia_${TIMESTAMP}.log"

# --- Mode selection ---
case "$1" in
    --dry-run) DRY_RUN=true; MODE="sanitize" ;;
    --restore) MODE="restore" ;;
    --delete-backups) MODE="delete_backups" ;;
esac

# --- Helper: Get most recent backup directory ---
latest_backup() {
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1
}

# --- Delete backups ---
if [[ "$MODE" == "delete_backups" ]]; then
    echo "⚠️ Deleting ALL backups..." | tee -a "$LOG_FILE"
    rm -rf "$BACKUP_ROOT"/*
    echo "✅ All backups deleted." | tee -a "$LOG_FILE"
    exit 0
fi

# --- Restore mode ---
if [[ "$MODE" == "restore" ]]; then
    LAST_BACKUP="$(latest_backup)"
    if [[ -z "$LAST_BACKUP" ]]; then
        echo "❌ No backups found to restore." | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "♻️ Restoring from: $LAST_BACKUP" | tee -a "$LOG_FILE"
    rsync -av "$LAST_BACKUP"/ ../ | tee -a "$LOG_FILE"
    echo "✅ Restore complete." | tee -a "$LOG_FILE"
    exit 0
fi

# --- Sanitization (dry or live) ---
if [[ ! -f "$EXCLUDE_FILE" ]]; then
    echo "❌ Exclusion file not found: $EXCLUDE_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

mapfile -t EXCLUDES < "$EXCLUDE_FILE"

if $DRY_RUN; then
    echo "🔍 Dry-run mode: No files will be modified." | tee -a "$LOG_FILE"
else
    echo "🧹 Live sanitization starting..." | tee -a "$LOG_FILE"
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
fi

# Loop through sibling <country_code> dirs, skipping list/logs/backups
find "$SCRIPT_DIR/.." -mindepth 1 -maxdepth 1 -type d \
    ! -name "$(basename "$SCRIPT_DIR")" \
    ! -name "logs" \
    ! -name "backups" | while read -r country_dir; do

    echo "🌍 Scanning: $(basename "$country_dir")" | tee -a "$LOG_FILE"

    # Skip nested logs/backups inside countries
    find "$country_dir" \( -type d -name "logs" -o -name "backups" \) -prune -o \
         -type f -name "*.txt" -print | while read -r file; do

        for name in "${EXCLUDES[@]}"; do
            [[ -z "$name" ]] && continue
            if grep -q -- "$name" "$file"; then
                if $DRY_RUN; then
                    echo "Would remove '$name' from: $file" | tee -a "$LOG_FILE"
                else
                    # Backup original before change
                    REL_PATH="${file#$SCRIPT_DIR/../}"
                    mkdir -p "$BACKUP_DIR/$(dirname "$REL_PATH")"
                    cp "$file" "$BACKUP_DIR/$REL_PATH"

                    echo "Removing '$name' from: $file" | tee -a "$LOG_FILE"
                    sed -i "/$name/d" "$file"
                fi
            fi
        done
    done
done

if $DRY_RUN; then
    echo "✅ Dry-run complete. No changes made." | tee -a "$LOG_FILE"
else
    echo "✅ Sanitization complete. Backup stored at: $BACKUP_DIR" | tee -a "$LOG_FILE"
fi
