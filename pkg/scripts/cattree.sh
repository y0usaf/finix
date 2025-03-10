#!/usr/bin/env bash

# cattree.sh - A script that combines tree and bat functionality
# Shows directory structure and file contents with proper indentation

set -e

# Check for required dependencies
check_dependencies() {
  if ! command -v bat &> /dev/null; then
    if command -v batcat &> /dev/null; then
      # On some systems, bat is installed as batcat
      alias bat="batcat"
    else
      echo "Error: 'bat' is required but not installed."
      echo "Please install it and try again."
      exit 1
    fi
  fi
}

# Default values
MAX_DEPTH=3
MAX_FILE_SIZE=10000 # in bytes
SHOW_HIDDEN=false
INDENT_SIZE=2
COLOR_MODE="auto"
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Function to print usage information
print_usage() {
  echo "Usage: cattree [OPTIONS] [PATH]"
  echo "Options:"
  echo "  -d, --max-depth DEPTH      Maximum depth to traverse (default: $MAX_DEPTH)"
  echo "  -s, --max-size SIZE        Maximum file size in bytes to display (default: $MAX_FILE_SIZE)"
  echo "  -a, --all                  Show hidden files and directories"
  echo "  -i, --indent SIZE          Indentation size (default: $INDENT_SIZE)"
  echo "  -c, --color MODE           Color mode: always, never, auto (default: $COLOR_MODE)"
  echo "  -w, --width WIDTH          Terminal width for wrapping (default: auto-detected)"
  echo "  -h, --help                 Show this help message"
  echo ""
  echo "PATH can be a directory or a file. If not specified, the current directory is used."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--max-depth)
      MAX_DEPTH="$2"
      shift 2
      ;;
    -s|--max-size)
      MAX_FILE_SIZE="$2"
      shift 2
      ;;
    -a|--all)
      SHOW_HIDDEN=true
      shift
      ;;
    -i|--indent)
      INDENT_SIZE="$2"
      shift 2
      ;;
    -c|--color)
      COLOR_MODE="$2"
      shift 2
      ;;
    -w|--width)
      TERM_WIDTH="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
    *)
      TARGET_PATH="$1"
      shift
      ;;
  esac
done

# Check dependencies
check_dependencies

# Set target path to current directory if not specified
TARGET_PATH="${TARGET_PATH:-.}"

# Check if path exists
if [[ ! -e "$TARGET_PATH" ]]; then
  echo "Error: '$TARGET_PATH' does not exist"
  exit 1
fi

# Function to create a horizontal line of specified length
create_horizontal_line() {
  local length=$1
  local char=$2
  local line=""
  for ((i=0; i<length; i++)); do
    line="${line}${char}"
  done
  echo "$line"
}

# Function to display file contents with proper indentation and syntax highlighting
display_file_contents() {
  local file=$1
  local prefix=$2
  local margin_size=${#prefix}
  local content_indent="    "
  local total_indent="${prefix}${content_indent}"
  local indent_size=$((margin_size + ${#content_indent}))
  
  # Calculate available width for content
  local content_width=$((TERM_WIDTH - indent_size - 2)) # -2 for the box character and space
  
  # Check file size
  local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
  if [[ $size -gt $MAX_FILE_SIZE ]]; then
    echo "${prefix}${content_indent}[File too large (${size} bytes), contents not shown]"
    return
  fi
  
  # Simple binary file check - try to read the first few bytes
  if [[ -n "$(LC_ALL=C tr -d '[:print:][:space:]' < "$file" | head -c 1)" ]]; then
    echo "${prefix}${content_indent}[Binary file, contents not shown]"
    return
  fi
  
  # Get the file extension for language detection
  local ext="${file##*.}"
  
  # Create horizontal lines for the box
  local horizontal_line=$(create_horizontal_line "$content_width" "─")
  
  # Display file contents with box drawing
  echo "${prefix}${content_indent}┌${horizontal_line}"
  
  # Create a temporary file for the bat output
  local tmp_file=$(mktemp)
  
  # Run bat with forced colors and save to temp file
  # Use --color=always to force color output regardless of terminal settings
  bat --color=always --style=plain --language="${ext}" --wrap=character --terminal-width=$content_width "$file" > "$tmp_file"
  
  # Read the temp file and add our prefix, preserving ANSI color codes
  while IFS= read -r line; do
    echo -e "${prefix}${content_indent}│ ${line}"
  done < "$tmp_file"
  
  # Clean up
  rm -f "$tmp_file"
  
  echo "${prefix}${content_indent}└${horizontal_line}"
}

# Tree characters
TREE_BRANCH="├── "
TREE_CORNER="└── "
TREE_VERTICAL="│   "
TREE_SPACE="    "

# Main function to recursively display directory structure and file contents
cattree() {
  local dir=$1
  local depth=$2
  local prefix=$3
  
  # List all files and directories in the current directory
  local items=()
  if [[ "$SHOW_HIDDEN" == "true" ]]; then
    mapfile -t items < <(ls -A "$dir" | sort)
  else
    mapfile -t items < <(ls "$dir" | sort)
  fi
  
  local count=${#items[@]}
  local index=0
  
  for item in "${items[@]}"; do
    index=$((index + 1))
    local is_last=$([[ $index -eq $count ]] && echo true || echo false)
    local item_path="$dir/$item"
    
    # Skip if item doesn't exist (might have been deleted)
    [[ ! -e "$item_path" ]] && continue
    
    # Print item name with proper indentation and tree structure
    if [[ "$is_last" == "true" ]]; then
      echo "${prefix}${TREE_CORNER}${item}"
      new_prefix="${prefix}${TREE_SPACE}"
    else
      echo "${prefix}${TREE_BRANCH}${item}"
      new_prefix="${prefix}${TREE_VERTICAL}"
    fi
    
    # If item is a directory, recursively process it
    if [[ -d "$item_path" && $depth -lt $MAX_DEPTH ]]; then
      cattree "$item_path" $((depth + 1)) "$new_prefix"
    # If item is a file, display its contents
    elif [[ -f "$item_path" ]]; then
      display_file_contents "$item_path" "$new_prefix"
    fi
  done
}

# Handle both files and directories
if [[ -d "$TARGET_PATH" ]]; then
  # It's a directory, process it normally
  echo "$TARGET_PATH"
  cattree "$TARGET_PATH" 0 ""
else
  # It's a file, just display its contents
  echo "$TARGET_PATH"
  display_file_contents "$TARGET_PATH" ""
fi

exit 0
