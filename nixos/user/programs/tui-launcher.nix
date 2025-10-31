{
  config,
  lib,
  ...
}: {
  options.user.programs.tui-launcher = {
    enable = lib.mkEnableOption "tui launcher";
  };
  config = lib.mkIf config.user.programs.tui-launcher.enable {
    usr = {
      files.".config/scripts/tui-launcher.sh" = {
        clobber = true;
        executable = true;
        text = ''
          #!/usr/bin/env bash
          shopt -s nullglob globstar
          set -o pipefail
          exec 3>/dev/null
          trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND" >&2; exit $s' ERR
          IFS=$'\n\t'
          DEL=$'\34'

          FZF_COMMAND="''${FZF_COMMAND:=fzf}"
          TERMINAL_COMMAND="''${TERMINAL_COMMAND:=''${TERMINAL:+$TERMINAL -e}}"
          TERMINAL_COMMAND="''${TERMINAL_COMMAND:-alacritty -e}"
          GLYPH_COMMAND="''${GLYPH_COMMAND- }"
          GLYPH_DESKTOP="''${GLYPH_DESKTOP- }"
          GLYPH_PROMPT="''${GLYPH_PROMPT- }"
          CONFIG_DIR="''${XDG_CONFIG_HOME:-${config.user.homeDirectory}/.config}/tui-launcher"
          PROVIDERS_FILE="''${PROVIDERS_FILE:=providers.conf}"
          if [[ "''${PROVIDERS_FILE#/}" == "''${PROVIDERS_FILE}" ]]; then
            PROVIDERS_FILE="''${CONFIG_DIR}/''${PROVIDERS_FILE}"
          fi
          if [[ ! -v PREVIEW_WINDOW ]]; then
              PREVIEW_WINDOW=up:3:border-rounded
          fi

          declare -A PROVIDERS
          if [ -f "''${PROVIDERS_FILE}" ]; then
            while IFS=$'\t' read -r provider_name list_cmd preview_cmd launch_cmd; do
              [[ -n "$provider_name" && -n "$list_cmd" && -n "$preview_cmd" && -n "$launch_cmd" ]] || continue
              PROVIDERS["$provider_name"]="''${list_cmd}''${DEL}''${preview_cmd}''${DEL}''${launch_cmd}"
            done < <(awk -F= '
            BEGINFILE{ provider=""; }
            /^\[.*\]/{sub("^\\[", "");sub("\\]$", "");provider=$0}
            /^(launch|list|preview)_cmd/{st = index($0,"=");providers[provider][$1] = substr($0,st+1)}
            ENDFILE{
              for (key in providers){
                if(!("list_cmd" in providers[key])){continue;}
                if(!("launch_cmd" in providers[key])){continue;}
                if(!("preview_cmd" in providers[key])){continue;}
                print key "\t" providers[key]["list_cmd"] "\t" providers[key]["preview_cmd"] "\t" providers[key]["launch_cmd"]
              }
            }' "''${PROVIDERS_FILE}")
          else
            PROVIDERS['desktop']="''${0} list-entries''${DEL}''${0} describe-desktop \"{1}\"''${DEL}''${0} run-desktop '{1}' {2}"
            PROVIDERS['command']="''${0} list-commands''${DEL}''${0} describe-command \"{1}\"''${DEL}''${TERMINAL_COMMAND} {1}"
          fi
          PROVIDERS['user']="exit''${DEL}exit''${DEL}{1}"

          function describe() {
            [[ -z "''${1}" || -z "''${PROVIDERS[''${1}]+x}" ]] && return 0
            readarray -d ''${DEL} -t PROVIDER_ARGS <<<"''${PROVIDERS[''${1}]}"
            local cmd="''${PROVIDER_ARGS[1]/\{1\}/''${2}}"
            [ -n "$cmd" ] && bash -c "$cmd" 2>/dev/null
          }
          function describe-desktop() {
            local name description generic
            name=$(grep -m 1 '^Name=' "$1" 2>/dev/null | cut -d'=' -f2-)
            description=$(grep -m 1 '^Comment=' "$1" 2>/dev/null | cut -d'=' -f2-)
            generic=$(grep -m 1 '^GenericName=' "$1" 2>/dev/null | cut -d'=' -f2-)
            echo -e "\033[33m''${name:-Unknown}\033[0m"
            echo "''${description:-''${generic:-No description}}"
          }
          function describe-command() {
            echo -e "\033[33m''${1}\033[0m"
            which "$1" 2>/dev/null || echo "Command: $1"
          }

          function provide() {
            [[ -z "$1" || -z "''${PROVIDERS[$1]+x}" ]] && return 0
            readarray -d ''${DEL} -t PROVIDER_ARGS <<<"''${PROVIDERS[$1]}"
            bash -c "''${PROVIDER_ARGS[0]}"
          }
          function list-commands() {
            compgen -c | sort -u | awk -v pre="$GLYPH_COMMAND" '{print $0 "\034command\034\033[31m" pre "\033[0m" $0}'
          }
          function list-entries() {
            # Get locations of desktop application folders according to spec
            # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
            IFS=':' read -ra DIRS <<<"''${XDG_DATA_HOME-${config.user.homeDirectory}/.local/share}:''${XDG_DATA_DIRS-/usr/local/share:/usr/share}"
            for i in "''${!DIRS[@]}"; do
              if [[ ! -d "''${DIRS[i]}" ]]; then
                unset -v 'DIRS[$i]'
              else
                DIRS[$i]="''${DIRS[i]}/applications/**/*.desktop"
              fi
            done

            # shellcheck disable=SC2068
            entries ''${DIRS[@]} | sort -k2
          }
          function entries() {
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
              $@ </dev/null
            # the empty stdin is needed in case no *.desktop files
          }
          function run-desktop() {
            CMD="$("''${0}" generate-command "$@" 2>&3)"
            echo "Generated Launch command from .desktop file: ''${CMD}" >&3
            bash -c "''${CMD}"
          }
          function generate-command() {
            # Define the search pattern that specifies the block to search for within the .desktop file
            PATTERN="^\\\\[Desktop Entry\\\\]"
            if [[ -n $2 ]]; then
              PATTERN="^\\\\[Desktop Action ''${2}\\\\]"
            fi
            echo "Searching for pattern: ''${PATTERN}" >&3
            # 1. We see a line starting [Desktop, but we're already searching: deactivate search again
            # 2. We see the specified pattern: start search
            # 3. We see an Exec= line during search: remove field codes and set variable
            # 3. We see a Path= line during search: set variable
            # 4. Finally, build command line
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

          case "$1" in
          describe | describe-desktop | describe-command | entries | list-entries | list-commands | generate-command | run-desktop | provide)
            "$@"
            exit
            ;;
          esac
          echo "Starting launcher instance with the following providers:" "''${!PROVIDERS[@]}" >&3

          TMPDIR=$(mktemp -d)
          FZFPIPE="''${TMPDIR}/fzf.pipe"
          mkfifo "$FZFPIPE"
          trap 'rm -rf "$TMPDIR"' EXIT INT

          # Iterate over providers and run their list-command
          for PROVIDER_NAME in "''${!PROVIDERS[@]}"; do
            ("''${0}" provide "''${PROVIDER_NAME}" >>"$FZFPIPE") &
          done

          readarray -t COMMAND_STR <<<$(
            ''${FZF_COMMAND} --ansi +s -x -d '\034' --nth ..3 --with-nth 3 \
              --print-query \
              --preview "$0 describe {2} {1}" \
              --preview-window="''${PREVIEW_WINDOW}" \
              --no-multi --cycle \
              --prompt="''${GLYPH_PROMPT}" \
              --border="rounded" \
              --header="" --no-info \
              <"$FZFPIPE"
          ) || exit 1
          # Get the last line of the fzf output. If there were no matches, it contains the query which we'll treat as a custom command
          # If there were matches, it contains the selected item
          COMMAND_STR=$(printf '%s\n' "''${COMMAND_STR[@]: -1}")
          # We still need to format the query to conform to our fallback provider.
          # We check for the presence of field separator character to determine if we're dealing with a custom command
          if [[ $COMMAND_STR != *$'\034'* ]]; then
              COMMAND_STR="''${COMMAND_STR}"$'\034user\034'"''${COMMAND_STR}"$'\034'
          fi

          [ -z "$COMMAND_STR" ] && exit 1

          # shellcheck disable=SC2086
          readarray -d $'\034' -t PARAMS <<<''${COMMAND_STR}
          # shellcheck disable=SC2086
          readarray -d ''${DEL} -t PROVIDER_ARGS <<<''${PROVIDERS[''${PARAMS[1]}]}
          # Substitute {1}, {2} etc with the correct values
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
  };
}
