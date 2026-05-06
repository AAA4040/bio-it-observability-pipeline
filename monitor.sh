#!/bin/bash

# Storing the path in a variable makes it easier to maintain
LOG_FILE="/app/med_app.log"

echo "--- Starting Medical Observability Monitor ---"

# Check if the file exists before starting to avoid container crash
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found! Please check your Docker volume mapping."
    exit 1
fi

# 'tail -f' is the standard for real-time log monitoring
tail -f "$LOG_FILE" | while read -r LINE
do
    # Use case statement for better readability and performance over multiple if/else
    case "$LINE" in
        *CRITICAL*)
            # Bold Red Background for Critical errors
            echo -e "\e[1;41m [CRITICAL] $LINE \e[0m"
            ;;
        *ERROR*)
            # Red text for Errors
            echo -e "\e[1;31m [ERROR] $LINE \e[0m"
            ;;
        *WARNING*)
            # Yellow text for Warnings
            echo -e "\e[1;33m [WARNING] $LINE \e[0m"
            ;;
        *)
            # Normal green text for healthy INFO logs
            echo -e "\e[1;32m [INFO] $LINE \e[0m"
            ;;
    esac
done