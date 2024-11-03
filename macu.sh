#!/bin/bash

# Create a temporary directory to store all the browser forensic data
OUTPUT_DIR="/tmp/browser_forensics_$(date +%Y%m%d%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Function to close all specified browsers
close_browsers() {
    echo "Closing Safari, Chrome, and Firefox..."
    killall "Safari" &> /dev/null
    killall "Google Chrome" &> /dev/null
    killall "firefox" &> /dev/null
}

# Function to extract history from a SQLite database
extract_history() {
    DB_PATH=$1
    OUTPUT_FILE=$2
    SQL_QUERY=$3

    if [ -f "$DB_PATH" ]; then
        sqlite3 "$DB_PATH" "$SQL_QUERY" >> "$OUTPUT_FILE"
    fi
}

# Close browsers to prevent database locking issues
close_browsers

# Loop through all user profiles on the system
for USER_HOME in /Users/*; do
    USER=$(basename "$USER_HOME")
    
    # Create a directory for each user within the output folder
    USER_OUTPUT_DIR="$OUTPUT_DIR/$USER"
    mkdir -p "$USER_OUTPUT_DIR"

    # Forensic Collection for Safari
    if [ -d "$USER_HOME/Library/Safari" ]; then
        echo "Collecting Safari data for user $USER..."
        mkdir -p "$USER_OUTPUT_DIR/Safari"

        cp "$USER_HOME/Library/Safari/History.db" /tmp/History.db
        SAFARI_HISTORY_DB="/tmp/History.db"
        SAFARI_OUTPUT_FILE="$USER_OUTPUT_DIR/Safari/history.csv"
        echo "URL, Title, Last Visited" > "$SAFARI_OUTPUT_FILE"
        extract_history "$SAFARI_HISTORY_DB" "$SAFARI_OUTPUT_FILE" \
        "SELECT history_items.url, history_items.title, datetime(history_visits.visit_time + 978307200, 'unixepoch', 'localtime') AS last_visited FROM history_items JOIN history_visits ON history_items.id = history_visits.history_item ORDER BY last_visited DESC;"
    fi

    # Forensic Collection for Google Chrome
    if [ -d "$USER_HOME/Library/Application Support/Google/Chrome" ]; then
        echo "Collecting Google Chrome data for user $USER..."
        mkdir -p "$USER_OUTPUT_DIR/Chrome"
        
        CHROME_HISTORY_DB="$USER_HOME/Library/Application Support/Google/Chrome/Default/History"
        CHROME_OUTPUT_FILE="$USER_OUTPUT_DIR/Chrome/history.csv"
        echo "URL, Title, Last Visited" > "$CHROME_OUTPUT_FILE"
        extract_history "$CHROME_HISTORY_DB" "$CHROME_OUTPUT_FILE" \
        "SELECT urls.url, urls.title, datetime(urls.last_visit_time/1000000-11644473600, 'unixepoch', 'localtime') AS last_visited FROM urls ORDER BY last_visited DESC;"
    fi

    # Forensic Collection for Mozilla Firefox
    if [ -d "$USER_HOME/Library/Application Support/Firefox" ]; then
        echo "Collecting Mozilla Firefox data for user $USER..."
        mkdir -p "$USER_OUTPUT_DIR/Firefox"
        
        FIREFOX_PROFILE_DIR="$USER_HOME/Library/Application Support/Firefox/Profiles"
        for PROFILE in "$FIREFOX_PROFILE_DIR"/*; do
            PROFILE_NAME=$(basename "$PROFILE")
            PROFILE_OUTPUT_DIR="$USER_OUTPUT_DIR/Firefox/$PROFILE_NAME"
            mkdir -p "$PROFILE_OUTPUT_DIR"

            FIREFOX_HISTORY_DB="$PROFILE/places.sqlite"
            FIREFOX_OUTPUT_FILE="$PROFILE_OUTPUT_DIR/history.csv"
            echo "URL, Title, Last Visited" > "$FIREFOX_OUTPUT_FILE"
            extract_history "$FIREFOX_HISTORY_DB" "$FIREFOX_OUTPUT_FILE" \
            "SELECT moz_places.url, moz_places.title, datetime(moz_historyvisits.visit_date/1000000, 'unixepoch', 'localtime') AS last_visited FROM moz_places JOIN moz_historyvisits ON moz_places.id = moz_historyvisits.place_id ORDER BY last_visited DESC;"
        done
    fi

done

# Zip the entire output directory for easy download
ZIPFILE="/tmp/browser_forensics_all_profiles_$(date +%Y%m%d%H%M%S).zip"
zip -r "$ZIPFILE" "$OUTPUT_DIR" > /dev/null

# Provide the location of the zipped forensic data
echo "Forensic data has been collected and zipped: $ZIPFILE"
