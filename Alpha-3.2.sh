#!/bin/bash

# Function to start the download
start_download() {
# Your download logic here
echo "Starting download..."
# Check if /etc/os-release exists
if [ -f "/etc/os-release" ]; then
    # Read the value of the ID variable from /etc/os-release
    source /etc/os-release
    case "$ID" in
        debian|ubuntu)
            echo "Detected Debian/Ubuntu"
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y python3-pip
            pip3 install configparser
            ;;
        centos|rhel|rocky)
            echo "Detected CentOS/RHEL/Rocky"
            sudo yum update -y
            sudo yum install -y python3-pip
            pip3 install configparser
            ;;
        fedora)
            echo "Detected Fedora"
            sudo dnf update -y
            sudo dnf install -y python3-pip
            pip3 install configparser
            ;;
        *)
            echo "Unsupported distribution: $ID"
            exit 1
            ;;
    esac
else
    echo "/etc/os-release not found. Unable to determine distribution."
    exit 1
fi

sudo tee /etc/systemd/system/Alpha.service > /dev/null <<EOF
[Unit]
Description=Check Service Python Script
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/Alpha.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/Alpha.py > /dev/null <<EOF
# Your Python script content here
import subprocess
import configparser
import time

# Configuration data as a multi-line string
config_data = """
[SERVICES]
services = json-convert, zeekctl
"""
# Add services Names here  

# Load configuration from the multi-line string
config = configparser.ConfigParser()
config.read_string(config_data)

# Get services from configuration
services = config['SERVICES']['services'].split(',')

class ServiceMonitor(object):
    def __init__(self, service):
        self.service = service

    def is_active(self):
        """Return True if service is running"""
        try:
            cmd = '/bin/systemctl status %s.service' % self.service
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            stdout_list = proc.communicate()[0].decode("utf-8").split("\n")
            for line in stdout_list:
                if 'Active:' in line:
                    if '(running)' in line:
                        print(self.service + " is running")
                        return True
            return False
        except Exception as e:
            return str(e)

    def start(self):
        """Restart service if not running"""
        try:
            cmd = '/bin/systemctl restart %s.service' % self.service
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            proc.communicate()
            print(self.service + " is restarted")
        except Exception as e:
            return str(e)

if __name__ == '__main__':
    while True:
        # Monitor and restart services
        for service in services:
            monitor = ServiceMonitor(service.strip())
            if not monitor.is_active():
                monitor.start()
        time.sleep(1)  # Sleep for 1 second before checking again

EOF
# Reload systemd to apply the changes
sudo systemctl daemon-reload
sudo systemctl restart Alpha.service
}

# Function to remove a file
remove_file() {
# Your file removal logic here
echo "Removing file..."

sudo systemctl stop Alpha.service
sudo systemctl disable Alpha.service
sudo rm -rf /etc/systemd/system/Alpha.service
sudo systemctl daemon-reload
}

# Menu for selecting options
while true; do
    echo "Choose an option:"
    echo "1. Start download"
    echo "2. Remove file"
    echo "3. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) start_download ;;
        2) remove_file ;;
        3) break ;;
        *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
    esac
done
