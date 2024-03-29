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
            sudo apt-get update && sudo apt-get install -y python3-pip python3-dev build-essential && pip3 install psutil
            ;;
        centos|rhel|rocky)
            echo "Detected CentOS/RHEL/Rocky"
            sudo yum update -y
            sudo yum install -y python3-pip
            pip3 install configparser
            sudo yum install python3-pip python3-devel && sudo yum install gcc python3-devel && pip3 install psutil
            ;;
        fedora)
            echo "Detected Fedora"
            sudo dnf update -y
            sudo dnf install -y python3-pip
            pip3 install configparser
            sudo dnf install python3-pip python3-devel redhat-rpm-config gcc && pip3 install psutil
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
Description=[SNB_TECH] Alpha-3.5 monitoring listing services & system resources
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/Alpha.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/Alpha.py > /dev/null <<EOF
import subprocess
import configparser
import time
import psutil

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

    def check_resources(self):
        """Check system resources and stop service if they are exceeded"""
        if psutil.virtual_memory().percent > 90:  # Example condition for high memory usage
            print("System resources exceeded, stopping service:", self.service)
            self.stop()

    def stop(self):
        """Stop service"""
        try:
            cmd = '/bin/systemctl stop %s.service' % self.service
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            proc.communicate()
            print(self.service + " is stopped")
        except Exception as e:
            return str(e)

if __name__ == '__main__':
    while True:
        # Check and stop services if system resources are exceeded
        for service in services:
            monitor = ServiceMonitor(service.strip())
            monitor.check_resources()

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
