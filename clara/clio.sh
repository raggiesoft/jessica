#!/bin/bash
#
# Clio - Git Operations Module for Daphne
# Location: ~/jessica/clara/clio.sh
#
# DESCRIPTION:
#   Clio is the historian of the Jessica suite — she keeps the codebase in sync
#   with its GitHub home and records every change in the audit logs.
#
#   She can:
#     - Pull the latest changes from the remote repo
#     - Push local commits upstream
#     - Show the current repo status
#     - Switch between branches
#
#   On a fresh clone, Clio will also bootstrap the central config (dorian)
#   from sample-dorian if it’s missing, so Jessica is immediately runnable.
#
#   All paths, colors, and log locations are loaded from the central config.

# === Load Central Config (with bootstrap) ===
CONFIG_FILE="$HOME/jessica/elise/dorian"
SAMPLE_CONFIG="$HOME/jessica/elise/sample-dorian"

bootstrap_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "\033[1;33mNo central config found at $CONFIG_FILE\033[0m"
        if [[ -f "$SAMPLE_CONFIG" ]]; then
            echo "Copying sample-dorian to create a new config..."
            mkdir -p "$(dirname "$CONFIG_FILE")"
            cp "$SAMPLE_CONFIG" "$CONFIG_FILE"
            echo -e "\033[1;32mConfig created from sample. Please edit $CONFIG_FILE with real values.\033[0m"
        else
            echo -e "\033[0;31mERROR: sample-dorian not found at $SAMPLE_CONFIG\033[0m"
        fi
    fi
}

bootstrap_config

if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# === Repo Location ===
# TOOL_HOME comes from Dorian and points to Jessica's root directory
REPO_DIR="$TOOL_HOME"

# === Function: Pull latest changes ===
git_pull() {
    echo -e "${GREEN}--- Pulling latest changes ---${NC}"
    echo "$(date '+%F %T') | Clio | Pull started" >> "$AUDIT_LOG"
    if git -C "$REPO_DIR" pull; then
        echo -e "${GREEN}Pull complete.${NC}"
    else
        echo -e "${RED}Pull failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Clio | Pull failed" >> "$ERROR_LOG"
    fi
}

# === Function: Push local commits ===
git_push() {
    echo -e "${GREEN}--- Pushing local commits ---${NC}"
    echo "$(date '+%F %T') | Clio | Push started" >> "$AUDIT_LOG"
    git -C "$REPO_DIR" add .
    read -rp "Commit message: " msg
    if git -C "$REPO_DIR" commit -m "$msg" && git -C "$REPO_DIR" push; then
        echo -e "${GREEN}Push complete.${NC}"
    else
        echo -e "${RED}Push failed.${NC}"
        echo "$(date '+%F %T') | ERROR | Clio | Push failed" >> "$ERROR_LOG"
    fi
}

# === Function: Show repo status ===
git_status() {
    echo -e "${GREEN}--- Git status ---${NC}"
    git -C "$REPO_DIR" status
}

# === Function: Switch branches ===
git_branch() {
    echo -e "${GREEN}--- Switch branch ---${NC}"
    git -C "$REPO_DIR" branch -a
    read -rp "Enter branch to switch to: " branch
    if git -C "$REPO_DIR" checkout "$branch"; then
        echo -e "${GREEN}Switched to $branch.${NC}"
    else
        echo -e "${RED}Branch switch failed.${NC}"
    fi
}

# === Clio's own submenu ===
while true; do
    echo
    echo "=== Clio: Git Operations (Jessica Repo) ==="
    echo "1) Pull latest changes"
    echo "2) Push local commits"
    echo "3) Show status"
    echo "4) Switch branch"
    echo "0) Return to Selene"
    read -rp "Choice: " choice
    case "$choice" in
        1) git_pull ;;
        2) git_push ;;
        3) git_status ;;
        4) git_branch ;;
        0) break ;;
        *) echo "Invalid choice." ;;
    esac
done
