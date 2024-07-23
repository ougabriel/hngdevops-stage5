#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Log the actions
log_message "Running devopsfetch with parameters: $@"

# Function to display help message
display_help() {
  cat <<EOF
Usage: devopsfetch [OPTIONS]
Options:
  -p, --port [PORT]         Display all active ports and services, or detailed info for a specific port
  -d, --docker [CONTAINER]  List all Docker images and containers, or detailed info for a specific container
  -n, --nginx [DOMAIN]      Display all Nginx domains and their ports, or detailed config info for a specific domain
  -u, --users [USERNAME]    List all users and their last login times, or detailed info for a specific user
  -t, --time [START_TIME] [END_TIME] Display activities within a specified time range
  -h, --help                Display this help message
EOF
}

# Function to display all active ports and services
display_ports() {
  log_message "Displaying ports info"
  if [ -z "$1" ]; then
    sudo netstat -tuln | awk 'NR>2 {print $1, $4}' | column -t
  else
    sudo lsof -i :$1
  fi
}

# Function to list all Docker images and containers
display_docker() {
  log_message "Displaying Docker info"
  if [ -z "$1" ]; then
    echo "Docker Images:"
    sudo docker images
    echo ""
    echo "Docker Containers:"
    sudo docker ps -a
  else
    sudo docker inspect $1
  fi
}

# Function to display all Nginx domains and their ports
display_nginx() {
  log_message "Displaying Nginx info"
  if [ -z "$1" ]; then
    sudo nginx -T | grep 'server_name' | awk '{print $2}'
  else
    sudo nginx -T | grep -A 10 "server_name $1;"
  fi
}

# Function to list all users and their last login times
display_users() {
  log_message "Displaying users info"
  if [ -z "$1" ]; then
    last -a | awk '{print $1, $3, $4, $5, $6, $7}' | uniq
  else
    last -a | grep "$1"
  fi
}

# Function to display activities within a time range
display_time() {
  log_message "Displaying activities from $1 to $2"
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: devopsfetch --time [START_TIME] [END_TIME]"
    exit 1
  fi
  
  # Validate date format (assuming YYYY-MM-DD HH:MM:SS)
  if ! date -d "$1" >/dev/null 2>&1 || ! date -d "$2" >/dev/null 2>&1; then
    echo "Invalid date format. Use YYYY-MM-DD HH:MM:SS"
    exit 1
  fi

  # Convert dates to seconds since epoch for comparison
  start_seconds=$(date -d "$1" +%s)
  end_seconds=$(date -d "$2" +%s)

  # Fetch last login info within the time range
  last -a | while IFS= read -r line; do
    login_time=$(echo "$line" | awk '{print $6, $7, $8}')
    login_seconds=$(date -d "$login_time" +%s 2>/dev/null)

    if [ "$login_seconds" -ge "$start_seconds" ] && [ "$login_seconds" -le "$end_seconds" ]; then
      echo "$line"
    fi
  done
}

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -p|--port) display_ports "$2"; shift ;;
    -d|--docker) display_docker "$2"; shift ;;
    -n|--nginx) display_nginx "$2"; shift ;;
    -u|--users) display_users "$2"; shift ;;
    -t|--time) display_time "$2" "$3"; shift 2 ;;
    -h|--help) display_help; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; display_help; exit 1 ;;
  esac
  shift
done

# If no arguments are passed, display help
if [ "$#" -eq 0 ]; then
  display_help
fi



