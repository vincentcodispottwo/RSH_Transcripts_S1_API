import socket
import re

# Define the UDP server address and port
UDP_IP = "10.0.0.4"
UDP_PORT = 1514

# Paths to the temp files
ACTIVITY_IDS_FILE = "/tmp/activity_ids.tmp"
PROCESSED_IDS_FILE = "/tmp/processed_activity_ids.tmp"

# Create a socket and bind it to the desired address and port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

print(f"Listening on {UDP_IP}:{UDP_PORT}...")

# Regular expression pattern to extract activityID from the syslog message
activity_id_pattern = re.compile(r"activityID=(\d+)")

try:
    while True:
        # Receive data from the socket (use a larger buffer size)
        data, addr = sock.recvfrom(4096)  # 4096 bytes buffer size

        # Decode the data to a string (assuming UTF-8 encoding)
        message = data.decode('utf-8', errors='ignore')  # Ignore errors to handle unexpected chars

        # Check if the message contains "|3400|" before processing
        if "|3400|" in message:
            # Search for the activityID in the received message
            match = activity_id_pattern.search(message)

            if match:
                activity_id = match.group(1)
                # Print the captured activityID to the terminal
                print(f"Captured activityID: {activity_id}")

                # Append the activityID to the monitored temp file
                with open(ACTIVITY_IDS_FILE, 'a') as f:
                    f.write(f"{activity_id}\n")

except KeyboardInterrupt:
    print("\nListener stopped by user.")
finally:
    sock.close()
