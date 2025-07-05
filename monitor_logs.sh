#!/bin/bash
#
#


set -euo pipefail


#############################################
# NGINX Log Monitor and Alert Script
# -------------------------------------------
# Runs NGINX setup, then watches for 500 errors
# in access log and sends alerts to Slack.
#############################################

LOG_FILE="/var/log/nginx/access.log"
ERROR_PATTERN="500"
ALERT_SCRIPT="/home/ubuntu/scripting-project/send_slack_alert.py"
SETUP_SCRIPT="./setup_nginx.sh"


#############################################
# Run NGINX Setup Script and Validate Success
# -------------------------------------------
# Executes the setup_nginx.sh script to configure
# and prepare NGINX. Aborts if the setup fails.
#############################################


# Step 1: Setup NGINX (only once at start)
bash "$SETUP_SCRIPT"

if [ $? -ne 0 ]; then
    echo "Aborting. nginx setup failed..."
    exit 1
else
    echo "Nginx setup done."
fi 


#############################################
# Validate Required Files Exist
# -------------------------------------------
# Ensures that the alert script and log file
# exist before continuing. Exits if not found.
#############################################

# Check if alert script exists
if [ ! -f "$ALERT_SCRIPT" ]; then
    echo "Error: Alert script '$ALERT_SCRIPT' not found"
    exit 1
fi

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found"
    exit 1
fi

#############################################
# Monitor Log File for Errors & Alert
# -------------------------------------------
# This watches the log file in real time for
# specific error patterns and calls a Python
# alert script when a match is found.
#############################################

echo " Monitoring $LOG_FILE for errors..."

tail -f "$LOG_FILE" | grep --line-buffered "$ERROR_PATTERN" | while read -r line; do
    echo " Error detected: $line"
    python3 "$ALERT_SCRIPT" "$line"
done


