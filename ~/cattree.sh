#!/bin/bash

# cattree - Display directory tree and file contents using bat
# Usage: cattree [directory] [file_pattern]

DIR="${1:-.}"  # Default to current directory if not specified
PATTERN="${2:-*}"  # Default to all files if pattern not specified

# Display directory structure first
echo "📁 Directory Structure:"
echo "======================="
find "$DIR" -type d | sort | sed -e "s/[^-][^\/]*\//  │   /g" -e "s/│\([^ ]\)/├── \1/"

# Display file contents with bat
echo ""
echo "📄 File Contents:"
echo "================="
find "$DIR" -type f -name "$PATTERN" | sort | while read file; do
    echo ""
    echo "File: $file"
    echo "-------------------"
    bat --style=plain --paging=never "$file"
    echo ""
done 