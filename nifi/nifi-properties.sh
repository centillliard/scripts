#!/bin/bash

# Script Name: sensitive-props-key.sh

# Version information
version="1.0.0"

# Function to show usage information
show_help() {
    echo "Usage: $0 [DIRECTORY] [ALPHA_NUMERIC_STRING] [--ver] [--help]"
    echo "Search and replace properties in nifi.properties files."
    echo
    echo "Changes made:"
    echo "  - 'nifi.sensitive.props.key=' will be replaced with [ALPHA_NUMERIC_STRING]"
    echo "  - 'nifi.state.management.embedded.zookeeper.start' will be set to 'true'"
    echo "  - 'nifi.cluster.is.node' will be set to 'true'"
    echo "  - 'nifi.zookeeper.connect.string' will be set based on available node directories"
    echo "  - 'nifi.cluster.load.balance.host' will be set based on the subdirectory name"
    echo
    echo "Options:"
    echo "  DIRECTORY             The directory to search for nifi.properties files"
    echo "  ALPHA_NUMERIC_STRING  The alphanumeric string to replace 'nifi.sensitive.props.key=' with"
    echo "  --ver                 Show version information"
    echo "  --help                Show this help message"
    echo
    echo "Example:"
    echo "  $0 /path/to/directory newKey123"
}

# Function to change the sensitive props key, zookeeper start property, cluster node property, zookeeper connect string, and load balance host
change_properties() {
    local dir=$1
    local new_key=$2
    local zk_connect_string=""

    # Build the ZooKeeper connect string from available node directories
    for node_dir in "$dir"/*; do
        if [ -d "$node_dir" ]; then
            local node_name=$(basename "$node_dir")
            zk_connect_string="$zk_connect_string$node_name:2181,"
        fi
    done
    # Remove the trailing comma from the ZooKeeper connect string
    zk_connect_string=${zk_connect_string%,}

    find "$dir" -type f -name 'nifi.properties' | while read -r file; do
        local edited=false
        local node_name=$(basename "$(dirname "$file")")
        
        # Change sensitive props key
        if grep -q 'nifi.sensitive.props.key=' "$file"; then
            sed -i "s/nifi.sensitive.props.key=[^ ]*/nifi.sensitive.props.key=$new_key/" "$file"
            edited=true
        else
            echo "No sensitive key found in: $file"
        fi
        
        # Change zookeeper start property
        if grep -q 'nifi.state.management.embedded.zookeeper.start=' "$file"; then
            sed -i "s/nifi.state.management.embedded.zookeeper.start=false/nifi.state.management.embedded.zookeeper.start=true/" "$file"
            edited=true
        else
            echo "No zookeeper start property found in: $file"
        fi

        # Change cluster node property
        if grep -q 'nifi.cluster.is.node=' "$file"; then
            sed -i "s/nifi.cluster.is.node=false/nifi.cluster.is.node=true/" "$file"
            edited=true
        else
            echo "No cluster node property found in: $file"
        fi

        # Change zookeeper connect string
        if grep -q 'nifi.zookeeper.connect.string=' "$file"; then
            sed -i "s|nifi.zookeeper.connect.string=.*|nifi.zookeeper.connect.string=$zk_connect_string|" "$file"
            edited=true
        else
            echo "No zookeeper connect string property found in: $file"
        fi

        # Change load balance host
        if grep -q 'nifi.cluster.load.balance.host=' "$file"; then
            sed -i "s|nifi.cluster.load.balance.host=.*|nifi.cluster.load.balance.host=$node_name|" "$file"
            edited=true
        else
            echo "No load balance host property found in: $file"
        fi
        
        # Print edited file path
        if [ "$edited" = true ]; then
            echo "Edited: $file"
        fi
    done
}

# Check for --ver or --help options
if [[ "$#" -eq 1 ]]; then
    case $1 in
        --ver)
            echo "Version: $version"
            exit 0
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            show_help
            exit 1
            ;;
    esac
fi

# Check for the correct number of arguments
if [[ "$#" -ne 2 ]]; then
    echo "Error: Incorrect number of arguments"
    show_help
    exit 1
fi

# Get the directory and new key from the arguments
directory=$1
new_key=$2

# Check if the provided directory is indeed a directory
if [[ ! -d "$directory" ]]; then
    echo "Error: The provided path is not a directory"
    exit 1
fi

# Validate the new key as an alphanumeric string
if [[ ! "$new_key" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "Error: The provided key is not an alphanumeric string"
    exit 1
fi

# Run the change function
change_properties "$directory" "$new_key"

