menu() {
    echo -e "${YELLOW}=== Daphne: Site Manager & Crew Dispatcher ===${NC}"
    echo "1) Phoebe  - Site creation & management"
    echo "2) Selene  - Update cycle (OS, Jessica repo, cleanup, restarts)"
    echo "3) Marina  - Backup & restore"
    echo "4) Iris    - Logs & monitoring"
    echo "5) Thalia  - Utilities"
    echo "6) Clio    - Git operations"
    echo "7) Helena  - Honeypot & router rotation"
    echo "8) Amanda  - Naming & creative generation"
    echo "9) Kristyn - Household wellness & crew check-in"
    echo "10) Aubrie - Keeper of web pages"
    echo "0) Exit"
}


case "$c" in
    1) "$SCRIPT_DIR/phoebe.sh" ;;
    2) "$SCRIPT_DIR/selene.sh" ;;
    3) "$SCRIPT_DIR/marina.sh" ;;
    4) "$SCRIPT_DIR/iris.sh" ;;
    5) "$SCRIPT_DIR/thalia.sh" ;;
    6) "$SCRIPT_DIR/clio.sh" ;;
    7) "$SCRIPT_DIR/helena.sh" ;;
    8) "$SCRIPT_DIR/amanda.sh" ;;
    9) "$SCRIPT_DIR/kristyn.sh" ;;
    10) "$SCRIPT_DIR/aubrie.sh" ;;
    0) echo "See you next time."; exit ;;
    *) echo -e "${RED}Invalid choice.${NC}" ;;
esac


