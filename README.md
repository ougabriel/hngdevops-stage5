# hngdevops-stage5

Here is the structure of this project directory:  

-   devopsfetch/
-   ├── devopsfetch.sh
-   ├── devopsfetch.service
-   ├── devopsfetch.logrotate  
-   ├── README.md
-   └── install.sh

## DevOps Mid Internship Task: Building `devopsfetch` for Server Information Retrieval and Monitoring

### Objective
I will be developing 
- A tool named `devopsfetch` to collect and display system information, including active ports, user logins, Nginx configurations, Docker images, and container statuses.
- Implementing a `systemd` service to monitor and log these activities continuously.

### Requirements as per project instructions

1. **Information Retrieval:**
   - **Ports:**
     - Display all active ports and services (`-p` or `--port`).
     - Provide detailed information about a specific port (`-p <port_number>`).
   - **Docker:**
     - List all Docker images and containers (`-d` or `--docker`).
     - Provide detailed information about a specific container (`-d <container_name>`).
   - **Nginx:**
     - Display all Nginx domains and their ports (`-n` or `--nginx`).
     - Provide detailed configuration information for a specific domain (`-n <domain>`).
   - **Users:**
     - List all users and their last login times (`-u` or `--users`).
     - Provide detailed information about a specific user (`-u <username>`).
   - **Time Range:**
     - Display activities within a specified time range (`-t` or `--time`).

2. **Output Formatting:**
   - Ensure all outputs are formatted for readability, in well-formatted tables with descriptive column names.

3. **Installation Script:**
   - Create a script to install necessary dependencies and set up a `systemd` service to monitor and log activities.
   - Implement continuous monitoring mode with logging to a file, ensuring log rotation and management.

4. **Help and Documentation:**
   - Implement a help flag (`-h` or `--help`) to provide usage instructions for the program.
   - Write clear and comprehensive documentation covering:
     - Installation and configuration steps.
     - Usage examples for each command-line flag.
     - The logging mechanism and how to retrieve logs.

### Steps

#### Step 1: Information Retrieval Functions

Create the `devopsfetch` script in Bash.

```bash
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
  -t, --time                Display activities within a specified time range
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

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -p|--port) display_ports "$2"; shift ;;
    -d|--docker) display_docker "$2"; shift ;;
    -n|--nginx) display_nginx "$2"; shift ;;
    -u|--users) display_users "$2"; shift ;;
    -t|--time) echo "Time range functionality not yet implemented"; shift ;;
    -h|--help) display_help; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; display_help; exit 1 ;;
  esac
  shift
done

# If no arguments are passed, display help
if [ "$#" -eq 0 ]; then
  display_help
fi
sleep 300 #Waits for 5 minutes before running again
done
```

Run the following command to copy the file to the `/usr/local/bin` location and set the right permissions needed for us to run the file
```bash
sudo cp /home/azureuser/devopsfetch/devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch
```

#### Step 2: Systemd Service Setup

Create a systemd service to monitor and log the activities.

1. **Create a `devopsfetch.service` file:**

```ini
[Unit]
Description=DevOpsFetch Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch.sh -p
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

2. **Copy the `devopsfetch` script to `/usr/local/bin` and make it executable:**

```bash
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch
```

3. **Move the service file to the systemd directory and enable it:**

```bash
sudo cp devopsfetch.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service
```

![image](https://github.com/user-attachments/assets/44749d5a-6ddd-48f4-9975-53f096209894)


#### Step 3: Logging and Log Rotation

1. **Set up logging in the `devopsfetch` script:**

Add logging functionality to the `devopsfetch` script.

```bash
LOG_FILE="/var/log/devopsfetch.log"

# Function to log messages
function log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Log the actions
log_message "Running devopsfetch with parameters: $@"

# Append logging to existing functions
function display_ports() {
  log_message "Displaying ports info"
  if [ -z "$1" ]; then
    sudo netstat -tuln | awk 'NR>2 {print $1, $4}' | column -t
  else
    sudo lsof -i :$1
  fi
}

# Similarly add log_message to other functions
```

2. **Set up log rotation:**
   
```bash
devopsfetch.logrotate
```
Add the following content to devopsfetch.logrotate:

```ini
/var/log/devopsfetch.log {
  daily
  missingok
  rotate 7
  compress
  delaycompress
  notifempty
  create 0640 root utmp
  sharedscripts
  postrotate
    /bin/systemctl reload devopsfetch.service > /dev/null 2>/dev/null || true
  endscript
}
```

#### Step 3: Run the scripts

 1. Copy the installation script content into install.sh:
 ```bash
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
```

 3. Make the install.sh script executable:
    ```sh
    chmod +x install.sh
    ```
 4.  Run the installation script:
 
   ```sh
   sudo ./install.sh
   ```

3. Start and enable the `devopsfetch` service:
   
   ```sh
   sudo systemctl start devopsfetch.service
   sudo systemctl enable devopsfetch.service
   ```
   Check its status
   
   ```sh
   sudo systemctl status devopsfetch.service
   ```
   

## Usage

- Display help:
  ```sh
  devopsfetch -h
  ```
![image](https://github.com/user-attachments/assets/6122609e-ef14-4f0d-b481-1d11b41357fe)

- Display all active ports and services:
  ```sh
  devopsfetch -p
  ```
![image](https://github.com/user-attachments/assets/189e6a4f-aac5-4a0c-842d-86ddc8dfdfc1)

- Display detailed information about a specific port:
  ```sh
  devopsfetch -p <port_number>
  ```


- List all Docker images and containers:
  ```sh
  devopsfetch -d
  ```
 ![image](https://github.com/user-attachments/assets/d8d4e83d-65af-43da-8b97-043bb85664b9)

- Display detailed information about a specific container:
  ```sh
  devopsfetch -d <container_name>
  ```

- Display all Nginx domains and their ports:
  ```sh
  devopsfetch -n
  ```

- Display detailed configuration information for a specific domain:
  ```sh
  devopsfetch -n <domain>
  ```
![image](https://github.com/user-attachments/assets/ec517e18-2110-4faa-94ea-533e26121028)

- List all users and their last login times:
  ```sh
  devopsfetch -u
  ```
![image](https://github.com/user-attachments/assets/a56baa7b-79f1-4981-b456-c903fbe02fe1)

- Display detailed information about a specific user:
  ```sh
  devopsfetch -u <username>
  ```

## Logging

Logs are stored in `/var/log/devopsfetch.log`. Log rotation is configured to keep logs for 7 days.

![image](https://github.com/user-attachments/assets/8ef3ec45-c4b4-4368-8516-39a2eb251690)


#### Step 5: Installation Script

Create an `install.sh` script to install dependencies and set up the `systemd` service.

```bash
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
```


###Troubleshooting
If changes are made to any part of the script, reload the `systemd` servicce

- Reload Systemd and Restart the Service
Reload the systemd configuration and restart the service.

```sh
sudo systemctl daemon-reload
sudo systemctl reset-failed devopsfetch.service
sudo systemctl start devopsfetch.service
sudo systemctl status devopsfetch.service
```
- If there is any error when the script is used we can check for Execution Errors
If the service still fails, check for detailed errors in the journal.
```sh
sudo journalctl -u devopsfetch.service -b
```
Look for any specific errors that might indicate what is going wrong.
![image](https://github.com/user-attachments/assets/a5e9df3a-a9c5-4fcf-a773-7378fa801d0a)


- To test the Script Manually
Manually run the script to ensure it works as expected.
```sh
sudo /usr/local/bin/devopsfetch.sh -p
```
This should output the active ports and services.
![image](https://github.com/user-attachments/assets/62e3fca0-562b-4724-b879-5950894977b1)


### Conclusion
With the given command outputs we have successfully deployed a  `devopsfetch` tool for retrieving and monitoring server information. The tool includes a `systemd` service for continuous monitoring and logging, with log rotation and comprehensive documentation for easy setup and usage.


Written by: Gabriel Okom for HNG Tech
