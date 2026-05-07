#!/bin/bash

# Configuration: Path to the log file inside the container
# This matches the volume mapping in docker-compose.yml
LOG_FILE="/data/med_app.log"
ALERT_FILE="/data/critical_alerts.log"

echo "--- Starting Medical Observability Monitor ---"
echo "Monitoring: $LOG_FILE"
echo "Alerts logged to: $ALERT_FILE"

# Pre-check: Ensure the log file exists before starting to avoid tail errors
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "[INFO] Created missing log file: $LOG_FILE"
fi

# Optimization: '-n 0' skips history and starts live streaming
# Pipeline: Stream log -> Read line by line -> Pattern matching
tail -n 0 -f "$LOG_FILE" | while read -r LINE
do
    case "$LINE" in
        *CRITICAL*)
            # Bold White text on Red Background for CRITICAL status
            echo -e "\e[1;41m [CRITICAL] $LINE \e[0m"
            # Persistence: Log the critical event to a dedicated alert file
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: $LINE" >> "$ALERT_FILE"
            ;;
        *ERROR*)
            # Red text for ERROR status
            echo -e "\e[1;31m [ERROR] $LINE \e[0m"
            ;;
        *WARNING*)
            # Yellow text for WARNING status
            echo -e "\e[1;33m [WARNING] $LINE \e[0m"
            ;;
        *)
            # Green text for healthy INFO status
            echo -e "\e[1;32m [INFO] $LINE \e[0m"
            ;;
    esac
done