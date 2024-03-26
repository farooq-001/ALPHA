import subprocess
import configparser
import time

# Configuration data as a multi-line string
config_data = """
[SERVICES]
services = wuauserv, Spooler
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
            cmd = 'sc query %s' % self.service
            output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
            if "RUNNING" in output.decode("utf-8"):
                print(self.service + " is running")
                return True
            return False
        except subprocess.CalledProcessError:
            return False

    def start(self):
        """Restart service if not running"""
        try:
            cmd = 'sc start %s' % self.service
            subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
            print(self.service + " is restarted")
        except subprocess.CalledProcessError as e:
            return str(e)

if __name__ == '__main__':
    while True:
        # Monitor and restart services
        for service in services:
            monitor = ServiceMonitor(service.strip())
            if not monitor.is_active():
                monitor.start()
        time.sleep(1)  # Sleep for 1 second before checking again
