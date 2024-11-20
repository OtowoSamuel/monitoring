#!/bin/bash

# Define variables
SERVICE="nginx"  # Or "apache2" depending on the service
LOGFILE="/var/log/service_status.log"
BACKUP_DIR="/var/backups/nginx"  # Or apache2
EMAIL="samuelotowo@gmail.com"    # Replace with your email

# Log timestamp and service status
echo "$(date) - Checking service status..." >> $LOGFILE

# Check if the service is running
if ! systemctl is-active --quiet $SERVICE; then
    echo "$(date) - $SERVICE is down! Attempting restart..." >> $LOGFILE

    # Attempt to restart the service
    if ! sudo systemctl restart $SERVICE; then
        echo "$(date) - $SERVICE restart failed! Sending alert email..." >> $LOGFILE

        # Send an alert email
        echo "$SERVICE is down and failed to restart!" | mail -s "$SERVICE Alert" $EMAIL
    else
        echo "$(date) - $SERVICE restarted successfully." >> $LOGFILE
    fi

    # Send an email alert for service down
    echo "$SERVICE is not running, attempting to restart..." | mail -s "$SERVICE Restart Alert" $EMAIL
else
    echo "$(date) - $SERVICE is running." >> $LOGFILE
fi

# Check CPU usage (log warning if it exceeds 80%)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "$(date) - WARNING: CPU usage is above 80% ($CPU_USAGE%)" >> $LOGFILE
else
    echo "$(date) - CPU usage is normal ($CPU_USAGE%)" >> $LOGFILE
fi

# Backup configuration files
echo "$(date) - Backing up $SERVICE configuration files..." >> $LOGFILE
mkdir -p $BACKUP_DIR
sudo tar -czf $BACKUP_DIR/backup_$(date '+%Y-%m-%d_%H:%M:%S').tar.gz -C /etc $SERVICE

echo "$(date) - Script execution complete." >> $LOGFILE

