# Function to start the download
start_download() {
    echo "Starting download..."
    # Python installation and package setup
    python -m pip install --upgrade pip
    python -m pip install configparser

    # Create Alpha service
    $serviceConfig = @"
[Unit]
Description=[SNB_TECH] Alpha-3.2 monitoring listing services
After=network.target

[Service]
Type=simple
ExecStart=C:\Users\Administrator\AppData\Local\Programs\Python\Python310\python.exe C:\Alpha.py
Restart=always

[Install]
WantedBy=multi-user.target
"@
    $serviceConfig | Out-File -FilePath 'C:\Alpha.service' -Encoding utf8

    # Create Alpha.py script
    $pythonScript = @"
# Your Python script content here
import subprocess
import configparser
import time

# Configuration data as a multi-line string
config_data = '''
[SERVICES]
services = json-convert, zeekctl
'''
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
        \"\"\"Return True if service is running\"\"\"
        try:
            cmd = 'sc query \"%s\" | findstr RUNNING' % self.service
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout_list = proc.communicate()[0].decode("utf-8").split("\\n")
            for line in stdout_list:
                if 'RUNNING' in line:
                    print(self.service + " is running")
                    return True
            return False
        except Exception as e:
            return str(e)

    def start(self):
        \"\"\"Restart service if not running\"\"\"
        try:
            cmd = 'sc start %s' % self.service
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
"@
    $pythonScript | Out-File -FilePath 'C:\Alpha.py' -Encoding utf8

    # Register and start the service
    sc.exe create Alpha binPath= "C:\Users\Administrator\AppData\Local\Programs\Python\Python310\python.exe C:\Alpha.py" start= auto
    sc.exe start Alpha
}

# Function to remove the service
remove_service() {
    echo "Removing service..."
    sc.exe stop Alpha
    sc.exe delete Alpha
    Remove-Item 'C:\Alpha.service'
    Remove-Item 'C:\Alpha.py'
}

# Menu for selecting options
while $true; do
    echo "Choose an option:"
    echo "1. Start download"
    echo "2. Remove service"
    echo "3. Exit"
    read -p "Enter your choice: " choice

    switch ($choice) {
        1 { start_download }
        2 { remove_service }
        3 { break }
        default { echo "Invalid choice. Please enter 1, 2, or 3." }
    }
done
