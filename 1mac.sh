#!/bin/bash
 
# Create a CSV file for output
OUTPUT_FILE="browser_history.csv"
 
# Remove existing output file if it exists
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi
 
# Write the header to the CSV file
echo "Timestamp,URL,Title,Browser" >> "$OUTPUT_FILE"
 
# Function to pull Safari history
pull_safari_history() {
    USER_HOME="/Users/$1"
    if [ -d "$USER_HOME/Library/Safari" ]; then
        HISTORY_FILE="$USER_HOME/Library/Safari/History.db"
        if [ -f "$HISTORY_FILE" ]; then
            sqlite3 "$HISTORY_FILE" "SELECT datetime(visit_time/1000000-978307200, 'unixepoch'), url, title FROM history_items ORDER BY visit_time DESC;" | while IFS="|" read -r timestamp url title; do
                echo "\"$timestamp\",\"$url\",\"$title\",\"Safari\"" >> "$OUTPUT_FILE"
            done
        fi
    fi
}
 
# Function to pull Chrome history
pull_chrome_history() {
    USER_HOME="/Users/$1"
    if [ -d "$USER_HOME/Library/Application Support/Google/Chrome/Default" ]; then
        HISTORY_FILE="$USER_HOME/Library/Application Support/Google/Chrome/Default/History"
        if [ -f "$HISTORY_FILE" ]; then
            sqlite3 "$HISTORY_FILE" "SELECT datetime(last_visit_time/1000000-11644473600, 'unixepoch'), url, title FROM urls ORDER BY last_visit_time DESC;" | while IFS="|" read -r timestamp url title; do
                echo "\"$timestamp\",\"$url\",\"$title\",\"Chrome\"" >> "$OUTPUT_FILE"
            done
        fi
    fi
}
 
# Function to pull Firefox history
pull_firefox_history() {
    USER_HOME="/Users/$1"
    if [ -d "$USER_HOME/Library/Application Support/Firefox/Profiles" ]; then
        PROFILE_DIR=$(find "$USER_HOME/Library/Application Support/Firefox/Profiles" -name "*.default-release" -type d | head -n 1)
        if [ -d "$PROFILE_DIR" ]; then
            HISTORY_FILE="$PROFILE_DIR/places.sqlite"
            if [ -f "$HISTORY_FILE" ]; then
                sqlite3 "$HISTORY_FILE" "SELECT datetime(last_visit_date/1000000, 'unixepoch'), url, title FROM moz_places ORDER BY last_visit_date DESC;" | while IFS="|" read -r timestamp url title; do
                    echo "\"$timestamp\",\"$url\",\"$title\",\"Firefox\"" >> "$OUTPUT_FILE"
                done
            fi
        fi
    fi
}
 
# Loop through all user accounts and gather history
for USER in $(dscl . list /Users | grep -v '^_'); do
    pull_safari_history "$USER"
    pull_chrome_history "$USER"
    pull_firefox_history "$USER"
done
 
echo "Browser history exported to $OUTPUT_FILE."