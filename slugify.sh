#!/bin/bash

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Get the original filename
original="$1"

# Check if file exists
if [ ! -e "$original" ]; then
    echo "Error: File '$original' not found"
    exit 1
fi

# Extract directory, basename, and extension
dir=$(dirname "$original")
base=$(basename "$original")
ext="${base##*.}"
name="${base%.*}"

# Convert name to lowercase and replace spaces with dashes
new_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Construct new filename
if [ "$ext" = "$base" ]; then
    # No extension
    new_file="$dir/$new_name"
else
    new_file="$dir/$new_name.$ext"
fi

# Rename the file
mv "$original" "$new_file"
echo "Renamed: $original -> $new_file"
