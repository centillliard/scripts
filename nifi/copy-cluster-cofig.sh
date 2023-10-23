#!/bin/bash

# Constants
VERSION="1.0.0"
USAGE="Usage: $0 -s <source_directory> -d <destination_directory> -f <hostnames_file> [--ver] [--help]"

# Function to display the help message
show_help() {
    echo "This script is used to copy NiFi configuration files from an old version of the cluster to a new version of the cluster."
    echo "It takes a list of hostnames from a file, and executes a series of copy commands on each host to transfer the configuration files."
    echo ""
    echo "$USAGE"
    echo ""
    echo "Options:"
    echo "  -s, --source      Source directory containing the NiFi configuration files of the old cluster version."
    echo "  -d, --destination Destination directory for the NiFi configuration files in the new cluster version."
    echo "  -f, --file        File containing a list of hostnames, one per line."
    echo "  --ver             Display the version of the script."
    echo "  --help            Display this help message."
}

# Parse command line arguments
SOURCE_DIR=""
DEST_DIR=""
HOSTNAMES_FILE=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--source) SOURCE_DIR="$2"; shift ;;
        -d|--destination) DEST_DIR="$2"; shift ;;
        -f|--file) HOSTNAMES_FILE="$2"; shift ;;
        --ver) echo "Version $VERSION"; exit 0 ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown parameter: $1"; echo "$USAGE"; exit 1 ;;
    esac
    shift
done

# Validate arguments
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ] || [ -z "$HOSTNAMES_FILE" ]; then
    echo "Error: Missing required arguments."
    echo "$USAGE"
    exit 1
fi

if [ ! -f "$HOSTNAMES_FILE" ]; then
    echo "Error: File '$HOSTNAMES_FILE' not found!"
    exit 1
fi

# Read hostnames into an array
mapfile -t hostnames < "$HOSTNAMES_FILE"

# Commands to be executed on each host
commands=(
    "cp $SOURCE_DIR/conf/flow.json.gz $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/flow.xml.gz $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/keystore.jks $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/truststore.jks $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/bootstrap.conf $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/zookeeper.properties $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/nifi.properties $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/state-management.xml $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/login-identity-providers.xml $DEST_DIR/conf"
    "cp $SOURCE_DIR/conf/users.xml $DEST_DIR/conf"   
    "cp $SOURCE_DIR/conf/templates/*.xml $DEST_DIR/conf/templates/"
    "cp $SOURCE_DIR/lib/*.nar $DEST_DIR/lib/"
    "cp -r $SOURCE_DIR/state $DEST_DIR/"
    "cp -r $SOURCE_DIR/lib/custom-libs $DEST_DIR/lib/"
)

# Loop through each hostname in the array and execute the commands
for hostname in "${hostnames[@]}"; do
    echo "Executing commands on host: $hostname"
    for cmd in "${commands[@]}"; do
        ssh "$hostname" "$cmd"
    done
    echo "Commands executed successfully on $hostname"
done

echo "Script execution completed!"

