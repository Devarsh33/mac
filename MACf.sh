#!/bin/bash

# Create a temporary directory to store all the browser forensic data
OUTPUT_DIR="/tmp/browser_forensics_$(date +%Y%m%d%H%M%S)"
mkdir -p "$OUTPUT_DIR"

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
        
        # Collect Safari History, Cookies, Downloads, Cache, and Extensions
        cp "$USER_HOME/Library/Safari/History.db" "$USER_OUTPUT_DIR/Safari/History.db" 2>/dev/null
        cp "$USER_HOME/Library/Cookies/Cookies.binarycookies" "$USER_OUTPUT_DIR/Safari/Cookies.binarycookies" 2>/dev/null
        cp "$USER_HOME/Library/Safari/Downloads.plist" "$USER_OUTPUT_DIR/Safari/Downloads.plist" 2>/dev/null
        cp -r "$USER_HOME/Library/Caches/com.apple.Safari/" "$USER_OUTPUT_DIR/Safari/Cache" 2>/dev/null
        cp -r "$USER_HOME/Library/Safari/Extensions/" "$USER_OUTPUT_DIR/Safari/Extensions" 2>/dev/null
    fi

    # Forensic Collection for Google Chrome
    if [ -d "$USER_HOME/Library/Application Support/Google/Chrome" ]; then
        echo "Collecting Google Chrome data for user $USER..."
        mkdir -p "$USER_OUTPUT_DIR/Chrome"
        
        # Default profile location for Chrome
        CHROME_PROFILE="$USER_HOME/Library/Application Support/Google/Chrome/Default"
        
        # Collect Chrome History, Cookies, Downloads, Cache, and Extensions
        cp "$CHROME_PROFILE/History" "$USER_OUTPUT_DIR/Chrome/History" 2>/dev/null
        cp "$CHROME_PROFILE/Cookies" "$USER_OUTPUT_DIR/Chrome/Cookies" 2>/dev/null
        cp "$CHROME_PROFILE/Downloads" "$USER_OUTPUT_DIR/Chrome/Downloads" 2>/dev/null
        cp -r "$USER_HOME/Library/Caches/Google/Chrome" "$USER_OUTPUT_DIR/Chrome/Cache" 2>/dev/null
        cp -r "$CHROME_PROFILE/Extensions" "$USER_OUTPUT_DIR/Chrome/Extensions" 2>/dev/null
    fi

    # Forensic Collection for Mozilla Firefox
    if [ -d "$USER_HOME/Library/Application Support/Firefox" ]; then
        echo "Collecting Mozilla Firefox data for user $USER..."
        mkdir -p "$USER_OUTPUT_DIR/Firefox"
        
        # Find Firefox profile(s)
        FIREFOX_PROFILE_DIR="$USER_HOME/Library/Application Support/Firefox/Profiles"
        for PROFILE in "$FIREFOX_PROFILE_DIR"/*; do
            PROFILE_NAME=$(basename "$PROFILE")
            PROFILE_OUTPUT_DIR="$USER_OUTPUT_DIR/Firefox/$PROFILE_NAME"
            mkdir -p "$PROFILE_OUTPUT_DIR"

            # Collect Firefox History, Cookies, Downloads, Cache, and Extensions
            cp "$PROFILE/places.sqlite" "$PROFILE_OUTPUT_DIR/History.sqlite" 2>/dev/null
            cp "$PROFILE/cookies.sqlite" "$PROFILE_OUTPUT_DIR/Cookies.sqlite" 2>/dev/null
            cp "$PROFILE/downloads.sqlite" "$PROFILE_OUTPUT_DIR/Downloads.sqlite" 2>/dev/null
            cp -r "$USER_HOME/Library/Caches/Firefox/Profiles/$PROFILE_NAME/" "$PROFILE_OUTPUT_DIR/Cache" 2>/dev/null
            cp -r "$PROFILE/extensions" "$PROFILE_OUTPUT_DIR/Extensions" 2>/dev/null
        done
    fi

done

# Zip the entire output directory for easy download
ZIPFILE="/tmp/browser_forensics_all_profiles_$(date +%Y%m%d%H%M%S).zip"
zip -r "$ZIPFILE" "$OUTPUT_DIR" > /dev/null

# Provide the location of the zipped forensic data
echo "Forensic data has been collected and zipped: $ZIPFILE"
