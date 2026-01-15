#!/bin/bash

# SentinelOne API Token
#The minimum permissions needed for this to work are: 
#Endpoint -> Download Remote Shell Transcript
#Activity -> View
S1_API_TOKEN=""

# Path to the file containing activityIDs (created by the Python script)
ACTIVITY_IDS_FILE="/tmp/activity_ids.tmp"

# Path to the temp file where you store the list of already processed IDs
PROCESSED_IDS_FILE="/tmp/processed_activity_ids.tmp"

# Ensure the file exists
touch "$ACTIVITY_IDS_FILE"
touch "$PROCESSED_IDS_FILE"

# Function to process the activityID
process_activity_id() {
  local activity_id="$1"
  
  # Make the first API call to get activity details
  response=$(curl -sS \
    -H "Authorization: ApiToken ${S1_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://s1-console/web/api/v2.1/activities?ids=${activity_id}")
  
  # Extract filePath, filename, and sessionId using jq
  filePath=$(echo "$response" | jq -r '.data[0].data.filePath')
  filename=$(echo "$response" | jq -r '.data[0].data.filename')
  sessionId=$(echo "$response" | jq -r '.data[0].data.channelId')  # Assuming sessionId is stored under 'channelId'
  
  # Check if filePath, filename, and sessionId were successfully extracted
  if [ -z "$filePath" ] || [ -z "$filename" ] || [ -z "$sessionId" ]; then
    echo "Error: filePath, filename, or sessionId not found in the response."
    return 1
  fi
  
  # Output filePath, filename, and sessionId
  echo "filePath: $filePath"
  echo "filename: $filename"
  echo "sessionId: $sessionId"
  
  # Modify the filename to include sessionId for uniqueness (e.g., sessionId_filename)
  download_filename="${sessionId}_${filename}"

  # Make the second API call to download the file, using the modified filename
  curl -sS \
    -H "Authorization: ApiToken ${S1_API_TOKEN}" \
    -o "$download_filename" \
    "https://s1-console/web/api/v2.1$filePath"
  
  # Output where the file was saved to disk
  echo "File saved as: $download_filename"
  echo ""
}

# Main loop that checks for new activity IDs
while true; do
  # Read the first activityID from the file
  activity_id=$(head -n 1 "$ACTIVITY_IDS_FILE")

  # If there's no new ID, wait for 5 seconds and try again
  if [ -z "$activity_id" ]; then
    sleep 5
    continue
  fi

  # Check if we've already processed this ID
  if grep -q "$activity_id" "$PROCESSED_IDS_FILE"; then
    # Skip this ID if it has already been processed
    sed -i '1d' "$ACTIVITY_IDS_FILE"  # Remove the processed ID from the list
    continue
  fi

  # Process the activityID
  process_activity_id "$activity_id"

  # Mark this ID as processed
  echo "$activity_id" >> "$PROCESSED_IDS_FILE"

  # Remove the processed ID from the list
  sed -i '1d' "$ACTIVITY_IDS_FILE"  # Remove the first line (processed activityID)
done
