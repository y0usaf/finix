{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.sway-launcher-desktop;
in {
  options.home.programs.sway-launcher-desktop = {
    enable = lib.mkEnableOption "sway launcher desktop";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      fzf
    ];
    users.users.y0usaf.maid.file.xdg_config."scripts/sway-launcher-desktop.sh" = {
      executable = true;
      text = ''
        shopt -s nullglob globstar
        set -o pipefail
        exec 3>/dev/null 2>/dev/null || true
        trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
        IFS=$'\n\t'
        DEL=$'\34'
        FZF_COMMAND="''${FZF_COMMAND:=fzf}"
        TERMINAL_COMMAND="''${TERMINAL_COMMAND:="$TERMINAL -e"}"
        GLYPH_COMMAND="''${GLYPH_COMMAND-  }"
        GLYPH_DESKTOP="''${GLYPH_DESKTOP-  }"
        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/sway-launcher-desktop"
        PROVIDERS_FILE="''${PROVIDERS_FILE:=providers.conf}"
        if [[ "''${PROVIDERS_FILE
          PROVIDERS_FILE="''${CONFIG_DIR}/''${PROVIDERS_FILE}"
        fi
        if [[ ! -v PREVIEW_WINDOW ]]; then
            PREVIEW_WINDOW=up:2:noborder
        fi
        declare -A PROVIDERS
        if [ -f "''${PROVIDERS_FILE}" ]; then
          eval "$(awk -F= '
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
          }' "''${PROVIDERS_FILE}")"
          if [[ ! -v HIST_FILE ]]; then
            HIST_FILE="''${XDG_CACHE_HOME:-$HOME/.cache}/''${0
          fi
        else
          PROVIDERS['desktop']="''${0} list-entries''${DEL}''${0} describe-desktop \"{1}\"''${DEL}''${0} run-desktop '{1}' {2}''${DEL}test -f '{1}' || exit 43"
          PROVIDERS['command']="''${0} list-commands''${DEL}''${0} describe-command \"{1}\"''${DEL}''${TERMINAL_COMMAND} {1}''${DEL}command -v '{1}' || exit 43"
          if [[ ! -v HIST_FILE ]]; then
            HIST_FILE="''${XDG_CACHE_HOME:-$HOME/.cache}/''${0
          fi
        fi
        PROVIDERS['user']="exit''${DEL}exit''${DEL}{1}"
        if [[ -n "''${HIST_FILE}" ]]; then
          mkdir -p "''${HIST_FILE%/*}" && touch "$HIST_FILE"
          readarray HIST_LINES <"$HIST_FILE"
        fi
        function describe() {
          readarray -d ''${DEL} -t PROVIDER_ARGS <<<''${PROVIDERS[''${1}]}
          [ -n "''${PROVIDER_ARGS[1]}" ] && eval "''${PROVIDER_ARGS[1]//\\{1\\}/''${2}}"
        }
        function describe-desktop() {
          description=$(sed -ne '/^Comment=/{s/^Comment=//;p;q}' "$1")
          echo -e "\033[33m$(sed -ne '/^Name=/{s/^Name=//;p;q}' "$1")\033[0m"
          echo "''${description:-No description}"
        }
        function describe-command() {
          readarray arr < <(whatis -l "$1" 2>/dev/null)
          description="''${arr[0]}"
          description="''${description
          echo -e "\033[33m''${1}\033[0m"
          echo "''${description:-No description}"
        }
        function provide() {
          readarray -d ''${DEL} -t PROVIDER_ARGS <<<''${PROVIDERS[$1]}
          eval "''${PROVIDER_ARGS[0]}"
        }
        function list-commands() {
          IFS=: read -ra path <<<"$PATH"
          for dir in "''${path[@]}"; do
            printf '%s\n' "$dir/"* |
              awk -F / -v pre="$GLYPH_COMMAND" '{print $NF "\034command\034\033[31m" pre "\033[0m" $NF;}'
          done | sort -u
        }
        function list-entries() {
          IFS=':' read -ra DIRS <<<"''${XDG_DATA_HOME-''${HOME}/.local/share}:''${XDG_DATA_DIRS-/usr/local/share:/usr/share}"
          for i in "''${!DIRS[@]}"; do
            if [[ ! -d "''${DIRS[i]}" ]]; then
              unset -v 'DIRS[$i]'
            else
              DIRS[$i]="''${DIRS[i]}/applications/**/*.desktop"
            fi
          done
          entries ''${DIRS[@]} | sort -k2
        }
        function entries() {
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
            $@ </dev/null
        }
        function run-desktop() {
          CMD="$("''${0}" generate-command "$@" 2>&3)"
          echo "Generated Launch command from .desktop file: ''${CMD}" >&3
          eval "''${CMD}"
        }
        function generate-command() {
          PATTERN="^\\\\[Desktop Entry\\\\]"
          if [[ -n $2 ]]; then
            PATTERN="^\\\\[Desktop Action ''${2}\\\\]"
          fi
          echo "Searching for pattern: ''${PATTERN}" >&3
          awk -v pattern="''${PATTERN}" -v terminal_cmd="''${TERMINAL_COMMAND}" -F= '
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
              if(path){ printf "cd " path " && " }
              printf "exec "
              if (terminal){ printf terminal_cmd " " }
              print exec
            }' "$1"
        }
        function shouldAutostart() {
            local condition="$(cat $1 | grep "AutostartCondition" | cut -d'=' -f2)"
            local filename="''${XDG_CONFIG_HOME-''${HOME}/.config}/''${condition
            case $condition in
                if-exists*)
                    [[ -e $filename ]]
                    ;;
                unless-exists*)
                    [[ ! -e $filename ]]
                    ;;
                *)
                    return 0
                    ;;
            esac
        }
        function autostart() {
          for application in $(list-autostart); do
              if shouldAutostart "$application" ; then
                  (exec setsid /bin/sh -c "$(run-desktop "''${application}")" &>/dev/null &)
              fi
          done
        }
        function list-autostart() {
          IFS=':' read -ra DIRS <<<"''${XDG_CONFIG_HOME-''${HOME}/.config}:''${XDG_CONFIG_DIRS-/etc/xdg}"
          for i in "''${!DIRS[@]}"; do
            if [[ ! -d "''${DIRS[i]}" ]]; then
              unset -v 'DIRS[$i]'
            else
              DIRS[$i]="''${DIRS[i]}/autostart/*.desktop"
            fi
          done
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
            ''${DIRS[@]} </dev/null
        }
        purge() {
         > "''${HIST_FILE}"
         declare -A PURGE_CMDS
         for PROVIDER_NAME in "''${!PROVIDERS[@]}"; do
           readarray -td ''${DEL} PROVIDER_ARGS <<<''${PROVIDERS[''${PROVIDER_NAME}]}
           PURGE_CMD=''${PROVIDER_ARGS[3]}
           [ -z "''${PURGE_CMD}" ] && PURGE_CMD='test -f "{1}" || exit 43'
           PURGE_CMDS[$PROVIDER_NAME]="''${PURGE_CMD%$'\n'}"
          done
          for HIST_LINE in "''${HIST_LINES[@]
            readarray -td $'\034' HIST_ENTRY <<<''${HIST_LINE}
            ENTRY=''${HIST_ENTRY[1]}
            readarray -td ' ' FILTER <<<''${PURGE_CMDS[$ENTRY]//\{1\}/''${HIST_ENTRY[0]}}
            (eval "''${FILTER[@]}" 1>/dev/null)
            if [[ $? -ne 43 ]]; then
              echo "1 ''${HIST_LINE[@]%$'\n'}" >> "''${HIST_FILE}"
            fi
          done
        }
        case "$1" in
        describe | describe-desktop | describe-command | entries | list-entries | list-commands | list-autostart | generate-command | autostart | run-desktop | provide | purge)
          "$@"
          exit
          ;;
        esac
        echo "Starting launcher instance with the following providers:" "''${!PROVIDERS[@]}" >&3
        FZFPIPE=$(mktemp -u)
        mkfifo "$FZFPIPE"
        trap 'rm "$FZFPIPE"' EXIT INT
        (printf '%s' "''${HIST_LINES[@]
        for PROVIDER_NAME in "''${!PROVIDERS[@]}"; do
          (bash -c "''${0} provide ''${PROVIDER_NAME}" >>"$FZFPIPE") &
        done
        readarray -t COMMAND_STR <<<$(
          ''${FZF_COMMAND} --ansi +s -x -d '\034' --nth ..3 --with-nth 3 \
            --print-query \
            --preview "$0 describe {2} {1}" \
            --preview-window="''${PREVIEW_WINDOW}" \
            --no-multi --cycle \
            --prompt="''${GLYPH_PROMPT-
            --header="" --no-info --margin="1,2" \
            --color='16,gutter:-1' \
            <"$FZFPIPE"
        ) || exit 1
        COMMAND_STR=$(printf '%s\n' "''${COMMAND_STR[@]: -1}")
        if [[ $COMMAND_STR != *$'\034'* ]]; then
            COMMAND_STR="''${COMMAND_STR}"$'\034user\034'"''${COMMAND_STR}"$'\034'
            SKIP_HIST=1
        fi
        [ -z "$COMMAND_STR" ] && exit 1
        if [[ -n "''${HIST_FILE}" && ! "$SKIP_HIST" ]]; then
          for i in "''${!HIST_LINES[@]}"; do
            if [[ "''${HIST_LINES[i]}" == *" $COMMAND_STR"$'\n' ]]; then
              HIST_COUNT=''${HIST_LINES[i]%% *}
              HIST_LINES[$i]="$((HIST_COUNT + 1)) $COMMAND_STR"$'\n'
              match=1
              break
            fi
          done
          if ! ((match)); then
            HIST_LINES+=("1 $COMMAND_STR"$'\n')
          fi
          printf '%s' "''${HIST_LINES[@]}" | sort -nr >"$HIST_FILE"
        fi
        readarray -d $'\034' -t PARAMS <<<''${COMMAND_STR}
        readarray -d ''${DEL} -t PROVIDER_ARGS <<<''${PROVIDERS[''${PARAMS[1]}]}
        COMMAND=''${PROVIDER_ARGS[2]//\{1\}/''${PARAMS[0]}}
        COMMAND=''${COMMAND//\{2\}/''${PARAMS[3]}}
        COMMAND=''${COMMAND%%[[:space:]]}
        if [ -t 1 ]; then
          echo "Launching command: ''${COMMAND}" >&3
          setsid /bin/sh -c "''${COMMAND}" >&/dev/null </dev/null &
          sleep 0.01
        else
          echo "''${COMMAND}"
        fi
      '';
    };
  };
}
