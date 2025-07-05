#!/bin/bash
#

set -euo pipefail


#############################################
# NGINX Directory and Configuration Paths
#############################################

# These paths are used to manage NGINX logs, configuration files,
# server blocks, and static HTML content. Make sure these directories
# and files exist before proceeding with operations.

LOG_DIR="/var/log/nginx"
LOG_FILE="$LOG_DIR/access.log"
NGINX_CONF="/etc/nginx/nginx.conf"
NGINX_BIN="/usr/sbin/nginx"  # reload nginx
SERVERS_DIR="/etc/nginx/conf.d"
HTML_DIR="/usr/share/nginx/html"  #stores the mapping of errors 500 type it should send own page
FASTAPI_CONF="/etc/nginx/conf.d/fastapi.conf"



#############################################
# NGINX Installation Check and Auto-Install
# ------------------------------------------
# Checks if NGINX is installed on the system.
# If not found, it updates package lists and
# installs NGINX using apt.
#############################################

check_nginx=$(command -v nginx)  #If nginx is installed and in your PATH, it prints the full path:
if [ -z "$check_nginx" ]; then
	echo "nginx not found. installing..."
	sudo apt update
	sudo apt install -y nginx
else
	echo "nginx found. No installation required"

fi

#############################################
# Ensure NGINX Log Directory Exists
#############################################

if [ ! -d "$LOG_DIR" ]; then #Checks if the directory does NOT exist
	echo "Creating log dir $LOG_DIR..."
	sudo mkdir -p "$LOG_DIR"
	sudo chown www-data:adm "$LOG_DIR"
	sudo chmod 755 "$LOG_DIR"
fi

#############################################
# Ensure NGINX Log File Exists and Is Writable
# --------------------------------------------
# Creates the log file if it doesn't exist,
# and sets appropriate ownership and permissions
# so NGINX can write to it without issues.
#############################################

if [ ! -f "$LOG_FILE" ]; then
       echo "Creating log file $LOG_FILE..."
       sudo touch "$LOG_FILE"
       sudo chown www-data:adm "$LOG_FILE"
       sudo chmod 644 "$LOG_FILE"
fi


#############################################
# Backup Existing NGINX Configuration
# ------------------------------------------
# Before applying our custom config, we back up
# the existing nginx.conf to prevent data loss.
#############################################

BACKUP_PATH="$NGINX_CONF.$(date '+%Y%m%d %H%M%S').bak"
sudo cp "$NGINX_CONF" "$NGINX_CONF.bak"
echo "Backup of original nginx.conf saved to $BACKUP_PATH"

#############################################
# Overwrite nginx.conf with Custom Configuration
# ---------------------------------------------
# Replaces the main NGINX configuration file
# with a predefined config using a heredoc block.
# Be sure to test with `nginx -t` after this step.
#############################################

sudo tee $NGINX_CONF > /dev/null << 'EOF'
user www-data;
worker_processes auto;
events {
       worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;

    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF



#############################################
# Ensure NGINX Server Block Directory Exists
# -------------------------------------------
# Creates the directory used for server configs
# (e.g., /etc/nginx/conf.d) if it's missing,
# and sets proper permissions.
#############################################

if [ ! -d "$SERVERS_DIR" ]; then
    echo "Creating servers directory $SERVERS_DIR..."
    sudo mkdir -p "$SERVERS_DIR"
    sudo chown root:root "$SERVERS_DIR"
    sudo chmod 755 "$SERVERS_DIR"
fi

#############################################
# Backup Existing FastAPI NGINX Server Block
#############################################


if [ -f "$FASTAPI_CONF" ]; then
    BACKUP_PATH="$FASTAPI_CONF.$(date '+%Y%m%d_%H%M%S').bak"
    sudo cp "$FASTAPI_CONF" "$BACKUP_PATH"
    echo "Backup of existing fastapi.conf saved to $BACKUP_PATH"
fi

#############################################
# Ensure fastapi.conf Server Block Exists
# ------------------------------------------
# Creates a default FastAPI server block config
# file if it doesn't exist in $SERVERS_DIR.
#############################################

if [ ! -f "$FASTAPI_CONF" ]; then
    echo "Creating default FastAPI server block at $FASTAPI_CONF..."
    sudo tee "$FASTAPI_CONF" > /dev/null << 'EOF'
server {
    listen 8080;
    server_name localhost;

    access_log /var/log/nginx/access.log;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

    sudo chown root:root "$FASTAPI_CONF"
    sudo chmod 644 "$FASTAPI_CONF"
fi


#############################################
# Ensure Custom 50x Error Page Exists
# ------------------------------------------
# This error page will be served when NGINX
# encounters 500, 502, 503, or 504 errors.
#############################################

if [ ! -f "$HTML_DIR/50x.html" ]; then
    echo "Creating 50x error page at $HTML_DIR/50x.html..."
    sudo tee "$HTML_DIR/50x.html" > /dev/null << 'EOF'
<html>
  <head><title>Server Error</title></head>
  <body>
    <h1>Oops! Something went wrong.</h1>
    <p>The server encountered an internal error. Please try again later.</p>
  </body>
</html>
EOF
fi

#############################################
# Start NGINX If Not Already Running
# -------------------------------------------
# This ensures the nginx service is active.
# If not running, it starts the service.
#############################################

if ! systemctl is-active --quiet nginx; then
    echo "Starting Nginx..."
    sudo systemctl start nginx
else
    echo "Nginx is already running."
fi


#############################################
# Validate and Reload NGINX Configuration
# ------------------------------------------
# Tests the nginx config file for syntax errors.
# If valid, reloads nginx gracefully to apply changes.
#############################################

validate_and_reload_nginx() {
    sudo $NGINX_BIN -t || { echo "Error: NGINX configuration test failed"; exit 1; }
    sudo systemctl reload nginx
    echo "Success: NGINX configured and reloaded"
}

validate_and_reload_nginx


