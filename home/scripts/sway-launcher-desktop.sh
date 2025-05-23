#!/usr/bin/env bash
# terminal application launcher for sway, using fzf
# Based on: https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher
# https://gist.github.com/Biont/40ef59652acf3673520c7a03c9f22d2a

shopt -s nullglob globstar
set -o pipefail

if ! { exec 0>&3; } 1>/dev/null 2>&1; then
  exec 3>/dev/null # If file descriptor 3 is unused in parent shell, output to /dev/null
fi

# shellcheck disable=SC2154
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

# Constants
readonly DEL=$'\34'  # Field separator character (ASCII 28)
readonly EXIT_CODE_MISSING=43  # Exit code for missing items
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"  # Logging level

# Utility Functions

# Log messages with different levels
# Usage: log_info "message" or log_error "message"
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >&3
}

log_info() {
    [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]] && log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_debug() {
    [[ "$LOG_LEVEL" == "DEBUG" ]] && log_message "DEBUG" "$1"
}

# Validate that a file exists and is readable
# Usage: validate_file "/path/to/file" || exit 1
validate_file() {
    local file="$1"
    if [[ -z "$file" ]]; then
        log_error "File path cannot be empty"
        return 1
    fi
    if [[ ! -f "$file" ]]; then
        log_error "File does not exist: $file"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        log_error "File is not readable: $file"
        return 1
    fi
    return 0
}

# Validate that a directory exists and is readable
# Usage: validate_directory "/path/to/dir" || exit 1
validate_directory() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        log_error "Directory path cannot be empty"
        return 1
    fi
    if [[ ! -d "$dir" ]]; then
        log_debug "Directory does not exist: $dir"
        return 1
    fi
    if [[ ! -r "$dir" ]]; then
        log_error "Directory is not readable: $dir"
        return 1
    fi
    return 0
}

# Safely execute a command with proper error handling
# Usage: safe_eval "command" || handle_error
safe_eval() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        log_error "Command cannot be empty"
        return 1
    fi
    log_debug "Executing: $cmd"
    eval "$cmd"
}

# Configuration and Setup
TERMINAL_COMMAND="${TERMINAL_COMMAND:="$TERMINAL -e"}"
GLYPH_COMMAND="${GLYPH_COMMAND-  }"
GLYPH_DESKTOP="${GLYPH_DESKTOP-  }"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sway-launcher-desktop"
PROVIDERS_FILE="${PROVIDERS_FILE:=providers.conf}"

if [[ "${PROVIDERS_FILE#/}" == "${PROVIDERS_FILE}" ]]; then
  # $PROVIDERS_FILE is a relative path, prepend $CONFIG_DIR
  PROVIDERS_FILE="${CONFIG_DIR}/${PROVIDERS_FILE}"
fi

# Provider config entries are separated by the field separator \034 and have the following structure:
# list_cmd,preview_cmd,launch_cmd,purge_cmd
declare -A PROVIDERS

if [[ -f "${PROVIDERS_FILE}" ]]; then
  log_info "Loading providers from: $PROVIDERS_FILE"
  if validate_file "${PROVIDERS_FILE}"; then
    safe_eval "$(awk -F= '
    BEGINFILE{ provider=""; }
    /^\[.*\]/{sub("^\\[", "");sub("\\]$", "");provider=$0}
    /^(launch|list|preview|purge)_cmd/{st = index($0,"=");providers[provider][$1] = substr($0,st+1)}
    ENDFILE{
      for (key in providers){
        if(!("list_cmd" in providers[key])){continue;}
        if(!("launch_cmd" in providers[key])){continue;}
        if(!("preview_cmd" in providers[key])){continue;}
        if(!("purge_cmd" in providers[key])){providers[key]["purge_cmd"] = "exit 0";}
        for (entry in providers[key]){
         gsub(/[\x27,\047]/,"\x27\"\x27\"\x27", providers[key][entry])
        }
        print "PROVIDERS[\x27" key "\x27]=\x27" providers[key]["list_cmd"] "\034" providers[key]["preview_cmd"] "\034" providers[key]["launch_cmd"] "\034" providers[key]["purge_cmd"] "\x27\n"
      }
    }' "${PROVIDERS_FILE}")"
  fi
  if [[ ! -v HIST_FILE ]]; then
    HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-${PROVIDERS_FILE##*/}-history.txt"
  fi
else
  log_info "No providers file found, using defaults"
  PROVIDERS['desktop']="${0} list-entries${DEL}${0} describe-desktop \"{1}\"${DEL}${0} run-desktop '{1}' {2}${DEL}test -f '{1}' || exit ${EXIT_CODE_MISSING}"
  PROVIDERS['command']="${0} list-commands${DEL}${0} describe-command \"{1}\"${DEL}${TERMINAL_COMMAND} {1}${DEL}command -v '{1}' || exit ${EXIT_CODE_MISSING}"
  if [[ ! -v HIST_FILE ]]; then
    HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-history.txt"
  fi
fi

PROVIDERS['user']="exit${DEL}exit${DEL}{1}" # Fallback provider that simply executes the exact command if there were no matches

# Initialize history
if [[ -n "${HIST_FILE}" ]]; then
  mkdir -p "${HIST_FILE%/*}" && touch "$HIST_FILE"
  readarray HIST_LINES <"$HIST_FILE"
  log_debug "Loaded ${#HIST_LINES[@]} history entries from $HIST_FILE"
fi

# Function: describe
# Description: Get description for a provider item
# Parameters: $1 - provider name, $2 - item identifier
describe() {
  local provider="$1"
  local item="$2"
  
  if [[ -z "$provider" || -z "$item" ]]; then
    log_error "describe: provider and item are required"
    return 1
  fi
  
  # shellcheck disable=SC2086
  readarray -d "${DEL}" -t PROVIDER_ARGS <<<"${PROVIDERS[$provider]}"
  # shellcheck disable=SC2086
  [[ -n "${PROVIDER_ARGS[1]}" ]] && safe_eval "${PROVIDER_ARGS[1]//\{1\}/$item}"
}

# Function: describe-desktop
# Description: Extract and display desktop file information
# Parameters: $1 - path to desktop file
describe-desktop() {
  local desktop_file="$1"
  
  if ! validate_file "$desktop_file"; then
    echo "Invalid desktop file"
    return 1
  fi
  
  local description name
  description=$(sed -ne '/^Comment=/{s/^Comment=//;p;q}' "$desktop_file")
  name=$(sed -ne '/^Name=/{s/^Name=//;p;q}' "$desktop_file")
  
  echo -e "\033[33m${name:-Unknown}\033[0m"
  echo "${description:-No description}"
}

# Function: describe-command
# Description: Get command description using whatis
# Parameters: $1 - command name
describe-command() {
  local cmd="$1"
  
  if [[ -z "$cmd" ]]; then
    log_error "describe-command: command name is required"
    return 1
  fi
  
  local description
  readarray arr < <(whatis -l "$cmd" 2>/dev/null)
  description="${arr[0]}"
  description="${description#* - }"
  
  echo -e "\033[33m${cmd}\033[0m"
  echo "${description:-No description}"
}

# Function: provide
# Description: Execute provider's list command
# Parameters: $1 - provider name
provide() {
  local provider="$1"
  
  if [[ -z "$provider" ]]; then
    log_error "provide: provider name is required"
    return 1
  fi
  
  # shellcheck disable=SC2086
  readarray -d "${DEL}" -t PROVIDER_ARGS <<<"${PROVIDERS[$provider]}"
  safe_eval "${PROVIDER_ARGS[0]}"
}

# Function: list-commands
# Description: List all available commands from PATH
list-commands() {
  local -a path_dirs
  IFS=: read -ra path_dirs <<<"$PATH"
  
  for dir in "${path_dirs[@]}"; do
    if validate_directory "$dir"; then
      printf '%s\n' "$dir/"* 2>/dev/null |
        awk -F / -v pre="$GLYPH_COMMAND" '{print $NF "\034command\034\033[31m" pre "\033[0m" $NF;}'
    fi
  done | sort -u
}

# Function: list-entries
# Description: List desktop application entries
list-entries() {
  local -a dirs
  IFS=':' read -ra dirs <<<"${XDG_DATA_HOME-${HOME}/.local/share}:${XDG_DATA_DIRS-/usr/local/share:/usr/share}"
  
  for i in "${!dirs[@]}"; do
    if ! validate_directory "${dirs[i]}"; then
      unset -v 'dirs[$i]'
    else
      dirs[$i]="${dirs[i]}/applications/**/*.desktop"
    fi
  done

  # shellcheck disable=SC2068
  entries ${dirs[@]} | sort -k2
}

# Function: entries
# Description: Process desktop files and extract entry information
# Parameters: $@ - glob patterns for desktop files
entries() {
  # shellcheck disable=SC2068
  awk -v pre="$GLYPH_DESKTOP" -F= '
    function desktopFileID(filename){
      sub("^.*applications/", "", filename);
      sub("/", "-", filename);
      return filename
    }
    BEGINFILE{
      application=0;
      hidden=0;
      block="";
      a=0

      id=desktopFileID(FILENAME)
      if(id in fileIds){
        nextfile;
      }else{
        fileIds[id]=0
      }
    }
    /^\[Desktop Entry\]/{block="entry"}
    /^Type=Application/{application=1}
    /^\[Desktop Action/{
      sub("^\\[Desktop Action ", "");
      sub("\\]$", "");
      block="action";
      a++;
      actions[a,"key"]=$0
    }
    /^\[X-/{
      sub("^\\[X-", "");
      sub("\\]$", "");
      block="action";
      a++;
      actions[a,"key"]=$0
    }
    /^Name=/{ (block=="action")? actions[a,"name"]=$2 : name=$2 }
    /^NoDisplay=true/{ (block=="action")? actions[a,"hidden"]=1 : hidden=1 }
    ENDFILE{
      if (application){
          if (!hidden)
              print FILENAME "\034desktop\034\033[33m" pre name "\033[0m";
          if (a>0)
              for (i=1; i<=a; i++)
                  if (!actions[i, "hidden"])
                      print FILENAME "\034desktop\034\033[33m" pre name "\033[0m (" actions[i, "name"] ")\034" actions[i, "key"]
      }
    }' \
    "$@" </dev/null
  # the empty stdin is needed in case no *.desktop files
}

# Function: run-desktop
# Description: Execute a desktop file
# Parameters: $1 - desktop file path, $2 - optional action
run-desktop() {
  local desktop_file="$1"
  local action="$2"
  
  if ! validate_file "$desktop_file"; then
    log_error "Invalid desktop file: $desktop_file"
    return 1
  fi
  
  local cmd
  cmd="$("${0}" generate-command "$desktop_file" "$action" 2>&3)"
  log_info "Generated Launch command from .desktop file: ${cmd}"
  safe_eval "${cmd}"
}

# Function: generate-command
# Description: Generate command from desktop file
# Parameters: $1 - desktop file path, $2 - optional action
generate-command() {
  local desktop_file="$1"
  local action="$2"
  
  if ! validate_file "$desktop_file"; then
    log_error "Invalid desktop file: $desktop_file"
    return 1
  fi
  
  local pattern="^\\\[Desktop Entry\\\]"
  if [[ -n "$action" ]]; then
    pattern="^\\\[Desktop Action ${action}\\\]"
  fi
  
  log_debug "Searching for pattern: ${pattern}"
  
  awk -v pattern="${pattern}" -v terminal_cmd="${TERMINAL_COMMAND}" -F= '
    BEGIN{a=0;exec=0;path=0}
       /^\[Desktop/{
        if(a){ a=0 }
       }
      $0 ~ pattern{ a=1 }
      /^Terminal=/{
        sub("^Terminal=", "");
        if ($0 == "true") { terminal=1 }
      }
      /^Exec=/{
        if(a && !exec){
          sub("^Exec=", "");
          gsub(" ?%[cDdFfikmNnUuv]", "");
          exec=$0;
        }
      }
      /^Path=/{
        if(a && !path){ path=$2 }
       }
    END{
      if(path){ printf "cd \"%s\" && ", path }
      printf "exec "
      if (terminal){ printf "%s ", terminal_cmd }
      print exec
    }' "$desktop_file"
}

# Function: shouldAutostart
# Description: Check if a desktop file should autostart based on conditions
# Parameters: $1 - desktop file path
shouldAutostart() {
    local desktop_file="$1"
    
    if ! validate_file "$desktop_file"; then
        return 1
    fi
    
    # Check if the file has an AutostartCondition entry
    if ! grep -q "^AutostartCondition=" "$desktop_file"; then
        return 0  # No condition means it should autostart
    fi
    
    local condition condition_type file_path filename
    condition="$(grep "^AutostartCondition=" "$desktop_file" | cut -d'=' -f2)"
    condition_type="${condition%% *}"
    file_path="${condition#* }"
    
    # Convert relative path to absolute using XDG config
    filename="${XDG_CONFIG_HOME:-${HOME}/.config}/${file_path}"
    
    case "$condition_type" in
        if-exists)
            [[ -e "$filename" ]]
            ;;
        unless-exists)
            [[ ! -e "$filename" ]]
            ;;
        *)
            log_error "Unknown AutostartCondition: $condition"
            return 0  # Default to starting if condition is unknown
            ;;
    esac
}

# Function: autostart
# Description: Start all autostart applications
autostart() {
  log_info "Checking autostart applications..."
  local count=0
  local application
  
  while IFS= read -r application; do
      if shouldAutostart "$application"; then
          log_info "Autostarting: $application"
          (exec setsid /bin/sh -c "$(run-desktop "${application}")" &>/dev/null &)
          count=$((count + 1))
      else
          log_debug "Skipping autostart for: $application (condition not met)"
      fi
  done < <(list-autostart)
  
  log_info "Autostarted $count applications"
}

# Function: list-autostart
# Description: List autostart desktop files
list-autostart() {
  local -a dirs
  IFS=':' read -ra dirs <<<"${XDG_CONFIG_HOME-${HOME}/.config}:${XDG_CONFIG_DIRS-/etc/xdg}"
  
  for i in "${!dirs[@]}"; do
    if ! validate_directory "${dirs[i]}"; then
      unset -v 'dirs[$i]'
    else
      dirs[$i]="${dirs[i]}/autostart/*.desktop"
    fi
  done

  # shellcheck disable=SC2068
  awk -v pre="$GLYPH_DESKTOP" -F= '
    function desktopFileID(filename){
      sub("^.*autostart/", "", filename);
      sub("/", "-", filename);
      return filename
    }
    BEGINFILE{
      application=0;
      block="";
      disabled=0;
      a=0

      id=desktopFileID(FILENAME)
      if(id in fileIds){
        nextfile;
      }else{
        fileIds[id]=0
      }
    }
    /^\[Desktop Entry\]/{block="entry"}
    /^Type=Application/{application=1}
    /^Name=/{ iname=$2 }
    /^Hidden=true/{disabled=1}
    ENDFILE{
      if (application && !disabled){
          print FILENAME;
      }
    }' \
    "${dirs[@]}" </dev/null 2>/dev/null
}

# Function: purge
# Description: Clean up history by removing invalid entries
purge() {
 # shellcheck disable=SC2188
 > "${HIST_FILE}"
 declare -A PURGE_CMDS
 local provider_name purge_cmd
 
 for provider_name in "${!PROVIDERS[@]}"; do
   readarray -td "${DEL}" PROVIDER_ARGS <<<"${PROVIDERS[$provider_name]}"
   purge_cmd=${PROVIDER_ARGS[3]}
   [[ -z "$purge_cmd" ]] && purge_cmd="test -f \"{1}\" || exit ${EXIT_CODE_MISSING}"
   PURGE_CMDS[$provider_name]="${purge_cmd%$'\n'}"
  done
  
  local hist_line hist_entry entry filter
  for hist_line in "${HIST_LINES[@]#*' '}"; do
    readarray -td $'\034' hist_entry <<<"${hist_line}"
    entry=${hist_entry[1]}
    readarray -td ' ' filter <<<"${PURGE_CMDS[$entry]//\{1\}/${hist_entry[0]}}"
    if (safe_eval "${filter[*]}" 1>/dev/null 2>&1); then
      echo "1 ${hist_line%$'\n'}" >> "${HIST_FILE}"
    fi
  done
}

# Main execution logic
case "$1" in
describe | describe-desktop | describe-command | entries | list-entries | list-commands | list-autostart | generate-command | autostart | run-desktop | provide | purge)
  "$@"
  exit
  ;;
esac

# Always ensure file descriptor 3 is open and valid
exec 3>/dev/null
log_info "Starting launcher instance with providers: ${!PROVIDERS[*]}"

FZFPIPE=$(mktemp -u)
mkfifo "$FZFPIPE"
trap 'rm -f "$FZFPIPE"' EXIT INT

# Append Launcher History, removing usage count
(printf '%s' "${HIST_LINES[@]#* }" >>"$FZFPIPE") &

# Iterate over providers and run their list-command
for PROVIDER_NAME in "${!PROVIDERS[@]}"; do
  (bash -c "${0} provide ${PROVIDER_NAME}" >>"$FZFPIPE") &
done

readarray -t COMMAND_STR <<<$(
  fzf --ansi +s -x -d '\034' --nth ..3 --with-nth 3 \
    --print-query \
    --preview "$0 describe {2} {1}" \
    --preview-window=up:2:noborder \
    --no-multi --cycle \
    --prompt="${GLYPH_PROMPT-# }" \
    --header='' --no-info --margin='1,2' \
    --color='16,gutter:-1' \
    <"$FZFPIPE"
) || exit 1

# Get the last line of the fzf output. If there were no matches, it contains the query which we'll treat as a custom command
# If there were matches, it contains the selected item
COMMAND_STR=$(printf '%s\n' "${COMMAND_STR[@]: -1}")

# We still need to format the query to conform to our fallback provider.
# We check for the presence of field separator character to determine if we're dealing with a custom command
if [[ $COMMAND_STR != *$'\034'* ]]; then
    COMMAND_STR="${COMMAND_STR}"$'\034user\034'"${COMMAND_STR}"$'\034'
    SKIP_HIST=1 # I chose not to include custom commands in the history. If this is a bad idea, open an issue please
fi

[[ -z "$COMMAND_STR" ]] && exit 1

# Update history
if [[ -n "${HIST_FILE}" && ! "$SKIP_HIST" ]]; then
  local match=0
  for i in "${!HIST_LINES[@]}"; do
    if [[ "${HIST_LINES[i]}" == *" $COMMAND_STR"$'\n' ]]; then
      local hist_count=${HIST_LINES[i]%% *}
      HIST_LINES[$i]="$((hist_count + 1)) $COMMAND_STR"$'\n'
      match=1
      break
    fi
  done
  if ! ((match)); then
    HIST_LINES+=("1 $COMMAND_STR"$'\n')
  fi

  printf '%s' "${HIST_LINES[@]}" | sort -nr >"$HIST_FILE"
fi

# Parse and execute command
# shellcheck disable=SC2086
readarray -d $'\034' -t PARAMS <<<"${COMMAND_STR}"
# shellcheck disable=SC2086
readarray -d "${DEL}" -t PROVIDER_ARGS <<<"${PROVIDERS[${PARAMS[1]}]}"

# Substitute {1}, {2} etc with the correct values
COMMAND=${PROVIDER_ARGS[2]//\{1\}/${PARAMS[0]}}
COMMAND=${COMMAND//\{2\}/${PARAMS[3]}}
COMMAND=${COMMAND%%[[:space:]]}

if [[ -t 1 ]]; then
  log_info "Launching command: ${COMMAND}"
  setsid /bin/sh -c "${COMMAND}" >&/dev/null </dev/null &
  sleep 0.01
else
  echo "${COMMAND}"
fi