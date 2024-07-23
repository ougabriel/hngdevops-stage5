#!/bin/bash

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y net-tools docker.io nginx

# Copy the script to /usr/local/bin and make it executable
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Copy the systemd service file and enable the service
sudo cp devopsfetch.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

# Set up log rotation
sudo cp devopsfetch.logrotate /etc/logrotate.d/devopsfetch

echo "Installation complete. The devopsfetch service is now running."

