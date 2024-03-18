#!/bin/bash

# Function to start the download
start_download() {
    # Your download logic here
    echo "Starting download..."
    sudo tee /etc/systemd/system/check-service.service > /dev/null <<EOF
[Unit]
Description=Check Service Python Script
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/check-service.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/check-service.py > /dev/null <<EOF
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
sudo systemctl restart check-service.service
}

# Function to remove a file
remove_file() {
    # Your file removal logic here
    echo "Removing file..."
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
