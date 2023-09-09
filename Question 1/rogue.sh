#!/bin/bash
#shebang by william hung. hope you know my reference
#note to myself:not sure this work or not as need to test and validate

#define the min and max file size thresholds bytes
#normally set min 5mb and max 5tb as never encouter linux server larger than 512GB storage before in working experience
#if want to use GB for either min or max threshold and want to set 5gb value for example use $((1024 * 1024 * 5)) which will output 5GB
MIN_THRESHOLD_SIZE=$((1024 * 1024 * 5))   #5MB 
MAX_THRESHOLD_SIZE=$((1024 * 1024 * 1024 * 5000))   #5TB maximum

# Human-readable thresholds
MIN_THRESHOLD_HR="5MB"
MAX_THRESHOLD_HR="5TB"

#directory monitor (change this to specific directory if needed).
MONITOR_DIR="/"  #this example will scan the root directory server and depend if CPU/ram/storage can handle the scanning or not

#email configuration (replace with other email details if require since this is example only)
#propose to use socketlab SMTP service as it have dashboard to monitor and can be scale depending on requirement 
TO_EMAIL="alarm@animapoint.net"
SMTP_SERVER="smtp.example.com"
SMTP_PORT="587"
SMTP_USERNAME="your_username"
SMTP_PASSWORD="your_password"
FROM_EMAIL="your_email@example.com"
SUBJECT="Rogue File Alert"

#save html to external storage as backup using curl (replace with prefer external storage details)
#this for auditing standby just in case
#remote SFTP upload the HTML file. example 'sftp://your-server.example.com/path/to/destination'.
#cloud storage. can specify the S3 bucket URL to the storage bucket or container. example 'https://s3.amazonaws.com/your-bucket-name'.
#USB storage. if server is physical, can use cheap USB 3.0 external drive as backup target. need to mount the USB device on your server and specify the path to the mounted directory.
EXTERNAL_STORAGE_URL="YOUR_EXTERNAL_STORAGE_URL"

#function start

#generate an HTML list of rogue files.
generate_html() {
  echo "<html><body>"
  echo "<h1>Rogue Files Found:</h1>"
  echo "<ul>"
  for FILE in $ROGUE_FILES; do
    echo "<li>$FILE</li>"
  done
  echo "</ul>"
  echo "</body></html>"
}

#save the HTML file to external storage using curl.
save_to_external_storage() {
  local html_content="$1"
  curl -X PUT -H "Content-Type: text/html" --data-binary "$html_content" "$EXTERNAL_STORAGE_URL"
}

#find the rogue files in the directory.
while true; do
  # Find files within the specified size range.
  ROGUE_FILES=$(find "$MONITOR_DIR" -type f -size +$MIN_THRESHOLD_SIZE -a -size -$MAX_THRESHOLD_SIZE)

  if [ -n "$ROGUE_FILES" ]; then
    HTML_CONTENT=$(generate_html)
    save_to_external_storage "$HTML_CONTENT"

#send an email with the HTML content.
    echo -e "$HTML_CONTENT" | mailx -s "$SUBJECT" -S smtp="$SMTP_SERVER:$SMTP_PORT" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="$SMTP_USERNAME" -S smtp-auth-password="$SMTP_PASSWORD" -S ssl-verify=ignore -r "$FROM_EMAIL" "$TO_EMAIL" -a "Content-Type: text/html"
  fi

#adjust the interval as needed. value in second (example below script sleep after 300 second or 5 minutes).
  sleep 300
done
