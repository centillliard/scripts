#!/bin/bash

version="1.0.0"

usage() {
  echo "Purpose: This script copies a specified directory to a specified location on multiple remote hosts."
  echo ""
  echo "Usage: $0 [options] <directory_to_copy> <file_with_hostnames> <destination_path>"
  echo ""
  echo "Options:"
  echo "  --help                Display this help message."
  echo "  --ver                 Display the version number."
  echo ""
  echo "Arguments:"
  echo "  <directory_to_copy>   The directory to copy."
  echo "  <file_with_hostnames> A file containing a list of hostnames."
  echo "  <destination_path>    The path to copy the directory to on the remote hosts."
  exit 1
}

# Check for help or version options
if [ "$#" -eq 1 ]; then
  if [ "$1" = "--help" ]; then
    usage
  elif [ "$1" = "--ver" ]; then
    echo "Version: $version"
    exit 0
  fi
fi

# Check if the right number of arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Error: Invalid number of arguments."
  usage
fi

# Assign arguments to variables
DIR_TO_COPY="$1"
HOSTS_FILE="$2"
DEST_PATH="$3"

# Check if the directory exists
if [ ! -d "$DIR_TO_COPY" ]; then
  echo "Error: Directory '$DIR_TO_COPY' does not exist."
  exit 1
fi

# Check if the file with host names exists
if [ ! -f "$HOSTS_FILE" ]; then
  echo "Error: File '$HOSTS_FILE' does not exist."
  exit 1
fi

# Read file content into an array
mapfile -t HOSTS_ARRAY < "$HOSTS_FILE"

# Copy directory to each host in the array
for HOST in "${HOSTS_ARRAY[@]}"; do
  echo "Copying $DIR_TO_COPY to $HOST:$DEST_PATH..."
  if scp -r "$DIR_TO_COPY" "$HOST:$DEST_PATH"; then
    echo "Successfully copied to $HOST:$DEST_PATH."
  else
    echo "Error copying to $HOST:$DEST_PATH."
  fi
done

echo "Done."

