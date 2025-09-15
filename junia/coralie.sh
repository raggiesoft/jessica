#!/bin/bash
#
# Coralie - Random Name Generator (modular suite edition)
# Supports infra (web-safe) + creative (accents kept) modes
# Family builder for creative mode full names
# Integrated with Lavinia for exclusion sweeps
#

# === Identity Variables ===
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NAME_LIST_DIR="$SCRIPT_DIR/list"
EXCLUDE_FILE="$SCRIPT_DIR/list/.exclude_names.txt"
LOG_FILE="$SCRIPT_DIR/logs/namegen.log"
LAVINIA="$SCRIPT_DIR/list/lavinia.sh"

# Ensure the log directory exists before trying to write to it
mkdir -p "$(dirname "$LOG_FILE")"

# === Color Codes ===
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# === Default Parameters ===
NATIONALITY="us"
NAME_TYPE="first"         # first, last, full
NAME_CASE="proper"        # proper, lower
NAME_MODE="infra"         # infra = web safe, creative = keep accents
GENDER="auto"             # auto, male, female
ERA=""                    # classic, boomer, genx, millennial, 90s, 2000s, 2010s, 2020s
USE_API=false
BATCH_COUNT=1
SAFE_OUTPUT=false

# === Functions ===
usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo "Running with no options will start interactive character creation mode."
    echo ""
    echo "Name generation options:"
    echo "  -n, --nat    [code]  : Nationality code (us, ca, future). Default: us"
    echo "  -t, --type   [type]  : first, last, or full. Default: first"
    echo "  -c, --case   [case]  : proper, lower. Default: proper"
    echo "  -m, --mode   [mode]  : infra, creative. Default: infra"
    echo "  -g, --gender [g]     : male, female, auto (first names only). Default: auto"
    echo "  -e, --era    [era]   : Name generation era (e.g., classic, boomer, genx, etc.)."
    echo "  -a, --use-api        : Force API instead of local files"
    echo "  -b, --batch  [num]   : Generate multiple names"
    echo "  -s, --safe           : Output filesystem-safe slug"
    echo "  -h, --help           : Show this help"
    exit 1
}

pluralize() {
    local name="$1"
    case "$name" in
        *s|*x|*z|*ch|*sh) echo "${name}es" ;;
        *) echo "${name}s" ;;
    esac
}

slugify() {
    echo "$1" | iconv -f UTF-8 -t ascii//TRANSLIT | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

normalize_name() {
    echo "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null
}

get_name_from_file() {
    local file_path=$1
    [ -f "$file_path" ] && shuf -n 1 "$file_path"
}

get_name_from_api() {
    local nat_code=$1
    # This function is a fallback and does not support era tagging
    curl -s "https://randomuser.me/api/?nat=${nat_code}&inc=name" | jq -r '.results[0].name' | awk '{print $1"|API"}'
}

get_name() {
    local name_source="$1"
    local gender="$2"
    local raw_line proper_name era_tag normalized_name check_name output_name

    while true; do
        local nat_dir="$NAME_LIST_DIR/$NATIONALITY"
        # Check for temporary mixed-era files first
        local temp_male_file="/tmp/coralie_male_mix.tmp"
        local temp_female_file="/tmp/coralie_female_mix.tmp"
        
        local name_file # Declare variable
        
        if [[ "$name_source" == "first" && "$gender" == "male" && -f "$temp_male_file" ]]; then
            name_file="$temp_male_file"
        elif [[ "$name_source" == "first" && "$gender" == "female" && -f "$temp_female_file" ]]; then
            name_file="$temp_female_file"
        else
            # Standard logic if not using mixed-era temp files
            local generic_name_file="$nat_dir/${gender}_first.txt"
            local era_name_file="$nat_dir/${gender}_first_${ERA}.txt"

            if [ "$name_source" == "first" ] && [ -n "$ERA" ] && [ -f "$era_name_file" ]; then
                name_file="$era_name_file"
            elif [ "$name_source" == "first" ]; then
                name_file="$generic_name_file"
            else # Last names
                name_file="$nat_dir/last.txt"
            fi
        fi

        if [ "$USE_API" = false ] && [ -f "$name_file" ]; then
            raw_line=$(get_name_from_file "$name_file")
        else
            [ "$USE_API" = true ] && echo "Forcing API lookup..." >&2
            local api_result
            api_result=$(get_name_from_api "$NATIONALITY")
            if [ "$name_source" == "last" ]; then
                proper_name=$(echo "$api_result" | jq -r '.last')
                raw_line="${proper_name}|API"
            else
                proper_name=$(echo "$api_result" | jq -r '.first')
                raw_line="${proper_name}|API"
            fi
        fi

        # Parse the line for name and era tag
        proper_name=$(echo "$raw_line" | cut -d'|' -f1 | xargs)
        era_tag=$(echo "$raw_line" | cut -d'|' -f2)

        normalized_name=$(normalize_name "$proper_name")
        check_name=$(echo "$normalized_name" | tr '[:upper:]' '[:lower:]')
        proper_name="$normalized_name"

        if ! [[ " ${EXCLUDE_NAMES[@]} " =~ " ${check_name} " ]]; then
            if [ "$NAME_CASE" == "lower" ]; then
                output_name=$(echo "$proper_name" | tr '[:upper:]' '[:lower:]')
            else
                output_name="$(tr '[:lower:]' '[:upper:]' <<< ${proper_name:0:1})${proper_name:1}"
            fi
            [ "$SAFE_OUTPUT" = true ] && output_name=$(slugify "$output_name")
            echo "${output_name}|${era_tag}" # Return name and era tag
            echo "$(date '+%F %T') | $name_source ($gender): $output_name ($era_tag)" >> "$LOG_FILE"
            break
        fi
    done
}

# Interactive Mode for Character Generation
interactive_mode() {
    # Clean up any old temp files on start and ensure cleanup on exit
    rm -f /tmp/coralie_*.tmp
    trap 'rm -f /tmp/coralie_*.tmp' EXIT

    echo -e "${GREEN}--- Interactive Character Generation ---${NC}"
    local MEN_COUNT WOMEN_COUNT same_last_choice
    local SAME_LAST=true
    local IS_MIXED_MODE=false
    local HEADER_ERA_NAME=""

    while true; do
        read -rp "How many men? " MEN_COUNT
        [[ "$MEN_COUNT" =~ ^[0-9]+$ ]] && break || echo -e "${RED}Please enter a number.${NC}"
    done

    while true; do
        read -rp "How many women? " WOMEN_COUNT
        [[ "$WOMEN_COUNT" =~ ^[0-9]+$ ]] && break || echo -e "${RED}Please enter a number.${NC}"
    done
    
    echo
    echo "Select a name generation mode:"
    echo "  1) Single Category (e.g., 'Future' or a specific 'Historical Era')"
    echo "  2) Mix Multiple Historical Eras"
    read -rp "Choice [1-2]: " mode_choice

    declare -A eras
    eras[1]="Classic"
    eras[2]="Boomer"
    eras[3]="GenX"
    eras[4]="Millennial"
    eras[5]="90s Baby"
    eras[6]="2000s Baby"
    eras[7]="2010s Baby"
    eras[8]="2020s Baby"
    
    declare -A era_files
    era_files[1]="classic"
    era_files[2]="boomer"
    era_files[3]="genx"
    era_files[4]="millennial"
    era_files[5]="90s"
    era_files[6]="2000s"
    era_files[7]="2010s"
    era_files[8]="2020s"

    if [[ "$mode_choice" == "2" ]]; then
        # Mix and Match Mode
        IS_MIXED_MODE=true
        NATIONALITY="us"
        ERA=""
        echo
        echo "Select the historical eras to mix (e.g., '4 5' for Millennial & 90s):"
        echo "  1) Classic      2) Boomer       3) GenX"
        echo "  4) Millennial   5) 90s Baby     6) 2000s Baby"
        echo "  7) 2010s Baby   8) 2020s Baby"
        read -rp "Enter numbers: " -a selected_indices

        for index in "${selected_indices[@]}"; do
            if [[ -v "era_files[$index]" ]]; then
                era_file_name=${era_files[$index]}
                era_display_name=${eras[$index]}
                echo "Adding names from era: $era_display_name"
                # Append era tag to each line for later parsing
                sed "s/$/|${era_display_name}/" "$NAME_LIST_DIR/us/male_first_${era_file_name}.txt" >> "/tmp/coralie_male_mix.tmp" 2>/dev/null
                sed "s/$/|${era_display_name}/" "$NAME_LIST_DIR/us/female_first_${era_file_name}.txt" >> "/tmp/coralie_female_mix.tmp" 2>/dev/null
            fi
        done

    else
        # Single Category Mode
        echo
        echo "Select a name category:"
        echo "  1) Historical (Classic, Boomer, etc.)"
        echo "  2) Far Future (Sci-Fi)"
        read -rp "Choice [1-2]: " category_choice
        if [[ "$category_choice" == "1" ]]; then
            NATIONALITY="us"
            echo
            echo "Select a single name era:"
            echo "  1) Classic      2) Boomer       3) GenX"
            echo "  4) Millennial   5) 90s Baby     6) 2000s Baby"
            echo "  7) 2010s Baby   8) 2020s Baby   9) Mixed (All Eras)"
            read -rp "Choice [1-9]: " era_choice
            if [[ -v "era_files[$era_choice]" ]]; then
                ERA=${era_files[$era_choice]}
                HEADER_ERA_NAME=${eras[$era_choice]}
            else
                ERA=""
            fi
        else
            NATIONALITY="future"
            ERA=""
            HEADER_ERA_NAME="Far Future"
        fi
    fi

    read -rp "Should they all share the same last name? [Y/n]: " same_last_choice
    same_last_choice=${same_last_choice:-Y}
    [[ "$same_last_choice" =~ ^[Nn]$ ]] && SAME_LAST=false

    NAME_MODE="creative"
    
    echo # Newline for cleaner output

    # Set the main header
    if $SAME_LAST; then
        last_name_line=$(get_name "last" "any")
        last_name=$(echo "$last_name_line" | cut -d'|' -f1)
        plural_last_name=$(pluralize "$last_name")
        echo -e "${YELLOW}--- Family: The ${plural_last_name} ---${NC}"
        if [[ -n "$HEADER_ERA_NAME" ]]; then
            echo -e "${YELLOW}(Names from the ${HEADER_ERA_NAME} Era)${NC}\n"
        else
            echo # Add a blank line if no era header
        fi
    elif [[ -n "$HEADER_ERA_NAME" ]]; then
        echo -e "${YELLOW}--- Names from the ${HEADER_ERA_NAME} Era ---${NC}\n"
    else
        echo -e "${YELLOW}--- Generated Characters ---${NC}\n"
    fi

    if [ "$MEN_COUNT" -gt 0 ]; then
        echo "Men:"
        for ((i=0; i<MEN_COUNT; i++)); do
            name_line=$(get_name "first" "male")
            first_name=$(echo "$name_line" | cut -d'|' -f1)
            era_tag=$(echo "$name_line" | cut -d'|' -f2)
            
            if $SAME_LAST; then
                output_name="$first_name $last_name"
            else
                last_name_line=$(get_name "last" "any")
                last_name=$(echo "$last_name_line" | cut -d'|' -f1)
                output_name="$first_name $last_name"
            fi

            if $IS_MIXED_MODE; then
                echo -e "  ${GREEN}$output_name${NC} ($era_tag)"
            else
                echo -e "  ${GREEN}$output_name${NC}"
            fi
        done
    fi
    
    # Add a space between sections only if both men and women are generated
    if [ "$MEN_COUNT" -gt 0 ] && [ "$WOMEN_COUNT" -gt 0 ]; then
        echo
    fi

    if [ "$WOMEN_COUNT" -gt 0 ]; then
        echo "Women:"
        for ((i=0; i<WOMEN_COUNT; i++)); do
            name_line=$(get_name "first" "female")
            first_name=$(echo "$name_line" | cut -d'|' -f1)
            era_tag=$(echo "$name_line" | cut -d'|' -f2)

            if $SAME_LAST; then
                output_name="$first_name $last_name"
            else
                last_name_line=$(get_name "last" "any")
                last_name=$(echo "$last_name_line" | cut -d'|' -f1)
                output_name="$first_name $last_name"
            fi

            if $IS_MIXED_MODE; then
                echo -e "  ${GREEN}$output_name${NC} ($era_tag)"
            else
                echo -e "  ${GREEN}$output_name${NC}"
            fi
        done
    fi
    echo
}

# === Load Excluded Names ===
EXCLUDE_NAMES=()
[ -f "$EXCLUDE_FILE" ] && mapfile -t EXCLUDE_NAMES < <(grep -v '^ *#' < "$EXCLUDE_FILE" | tr '[:upper:]' '[:lower:]' | xargs)

# === Script Entry Point ===
if [[ "$1" == "--sanitize" || "$1" == "--restore" || "$1" == "--delete-backups" ]]; then
    if [[ -x "$LAVINIA" ]]; then "$LAVINIA" "$1"; exit $?; else echo -e "${RED}⚠️ Lavinia not found or not executable at: $LAVINIA${NC}"; exit 1; fi
fi

if [[ "$1" == "--sanitize-before" ]]; then
    shift
    if [[ -x "$LAVINIA" ]]; then echo "🧹 Running Lavinia before generating names..."; "$LAVINIA" --sanitize; else echo -e "${RED}⚠️ Lavinia not found or not executable at: $LAVINIA${NC}"; fi
fi

if [ "$#" -eq 0 ]; then
    interactive_mode
    exit 0
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--nat) NATIONALITY="$2"; shift;;
        -t|--type) NAME_TYPE="$2"; shift;;
        -c|--case) NAME_CASE="$2"; shift;;
        -m|--mode) NAME_MODE="$2"; shift;;
        -g|--gender) GENDER="$2"; shift;;
        -e|--era) ERA="$2"; shift;;
        -a|--use-api) USE_API=true;;
        -b|--batch) BATCH_COUNT="$2"; shift;;
        -s|--safe) SAFE_OUTPUT=true;;
        -h|--help) usage;;
        *) echo "Unknown param: $1"; usage;;
    esac
    shift
done

if [[ "$NAME_MODE" == "creative" && "$NAME_TYPE" == "full" ]]; then
    echo -e "${RED}For creative full names, please use the interactive mode (run without arguments).${NC}"; exit 1;
fi

for ((i=0; i<BATCH_COUNT; i++)); do
    case $NAME_TYPE in
        "first")
            if [ "$GENDER" == "auto" ]; then gender=$([ $((RANDOM % 2)) -eq 0 ] && echo "female" || echo "male"); else gender=$GENDER; fi
            name_line=$(get_name "first" "$gender")
            echo "$name_line" | cut -d'|' -f1 # Only output the name for command-line use
            ;;
        "last")
            name_line=$(get_name "last" "any")
            echo "$name_line" | cut -d'|' -f1
             ;;
        "full")
            first_gender=$([ $((RANDOM % 2)) -eq 0 ] && echo "female" || echo "male")
            first_name_line=$(get_name "first" "$first_gender")
            first_name=$(echo "$first_name_line" | cut -d'|' -f1)
            last_name_line=$(get_name "last" "any")
            last_name=$(echo "$last_name_line" | cut -d'|' -f1)
            echo "$first_name $last_name"
            ;;
    esac
done