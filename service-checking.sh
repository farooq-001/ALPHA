#!/bin/bash

# Function to start the download
start_download() {
    # Your download logic here
    echo "Starting download..."
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
