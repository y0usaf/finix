{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrByPath filterAttrs generators mapAttrs mkEnableOption mkIf mkOption optionals optionalAttrs types;
  inherit (types) anything attrsOf bool str;
  inherit (config) user;

  ghEnabled = attrByPath ["user" "tools" "gh" "enable"] false config;
  agentSlackEnabled = attrByPath ["user" "dev" "agent-slack" "enable"] false config;

  # ---------------------------------------------------------------------------
  # Settings defaults (was data/settings-defaults.nix)
  # ---------------------------------------------------------------------------
  ccSettings = {
    includeCoAuthoredBy = false;
    promptSuggestionEnabled = false;
    skipDangerousModePermissionPrompt = true;
    permissions = {
      defaultMode = "bypassPermissions";
    };
    env = {
      DISABLE_TELEMETRY = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
  };

  # ---------------------------------------------------------------------------
  # Instructions text (was data/instructions-text.nix)
  # ---------------------------------------------------------------------------
  claudeCodeInstructions = ''
    <system>
      <environment>NixOS</environment>
      <rules>
        <rule>Use <code>nix shell -p <package></code> to run tools not on the system.</rule>
        <rule>Use <code>bun</code> and <code>bunx</code> instead of npm, npx, or yarn.</rule>
        <rule>Use CLIs for external services (e.g. linear, vercel, gh) over API calls or web interfaces.</rule>
        <rule>For Linear tasks, use the <code>linear</code> CLI and do not use a Linear MCP server.</rule>
      </rules>
    </system>
  '';

  # ---------------------------------------------------------------------------
  # Statusline (was data/statusline.nix)
  # ---------------------------------------------------------------------------
  statuslineScript = pkgs.writeShellApplication {
    name = "statusline";
    runtimeInputs = [pkgs.jq pkgs.git pkgs.ncurses pkgs.bun];
    checkPhase = "";
    text = ''
      DATA=$(cat);COLS=$(tput cols 2>/dev/null||echo 120)
      eval "$(jq -r '
        def pct:try(if(.context_window.remaining_percentage//null)!=null then 100-(.context_window.remaining_percentage|floor)
          elif(.context_window.context_window_size//0)>0 then((.context_window.current_usage.input_tokens//0)+(.context_window.current_usage.cache_creation_input_tokens//0)+(.context_window.current_usage.cache_read_input_tokens//0))*100/(.context_window.context_window_size)|floor
          else 0 end)catch 0;
        @sh"MODEL=\(.model.display_name//\"Claude\") MODEL_ID=\(try(.model.id//\"unknown\")catch\"unknown\") DIR=\(.cwd//\"~\"|split(\"/\")|last) PCT=\(pct) CTX_K=\((.context_window.context_window_size//200000)/1000) DUR_MS=\(.cost.total_duration_ms//0) AGENT=\(.agent.name//\"\") MODE=\(.mode//\"\") SCOST=\(.cost.total_cost_usd//0)"'<<<"$DATA")"
      CF="$HOME/.claude/cost-cache.json"
      _cfr(){ local d;d=$(bunx ccusage daily --since "$(date +%Y%m01)" --json 2>/dev/null)||return
        jq --arg d "$(date +%Y-%m-%d)" --arg w "$(date -d'last monday' +%Y-%m-%d 2>/dev/null||date +%Y-%m-%d)" \
          '{d:[.daily[]|select(.date==$d)|.totalCost]|add//0,w:[.daily[]|select(.date>=$w)|.totalCost]|add//0,m:[.daily[].totalCost]|add//0}'<<<"$d" \
          >"''${CF}.tmp"&&mv "''${CF}.tmp" "$CF";}
      CA=9999;[ -f "$CF" ]&&CA=$(($(date +%s)-$(stat -c%Y "$CF" 2>/dev/null||echo 0)))
      ((CA>=60))&&{ ((CA>300))&&{ _cfr 2>/dev/null||true;}||{ (_cfr 2>/dev/null||true)&disown 2>/dev/null;};}
      read -r F_S F_D F_W F_M < <(jq -r --argjson s "''${SCOST:-0}" '
        def fc:if.<0.01 then"$0"elif.<10 then"$\(.*100|round/100)"elif.<100 then"$\(.*10|round/10)"else"$\(round)"end;
        "\($s|fc) \(.d//0|fc) \(.w//0|fc) \(.m//0|fc)"' "$CF" 2>/dev/null||echo '$0 $0 $0 $0')
      R=$'\033[0m' B=$'\033[1m'
      B1=$'\033[0;48;5;4m' F1=$'\033[38;5;0m' D1=$'\033[38;5;8m'
      B2=$'\033[0;48;5;0m' F2=$'\033[38;5;7m' D2=$'\033[38;5;4m'
      cG=$'\033[0;48;5;0;38;5;2m' cY=$'\033[0;48;5;0;38;5;3m' cR=$'\033[0;48;5;0;38;5;1m' cM=$'\033[0;48;5;0;38;5;5m'
      case "$MODEL_ID" in *opus*)TI=$'\xee\xb5\xa2';;*sonnet*)TI=$'\xee\xb8\xb4';;*haiku*)TI=$'\xee\x9f\x95';;*)TI=$'\xef\x84\x91';;esac
      BR=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)||BR=""
      GS=""
      [ -n "$BR" ]&&{
        read -r s m u < <(paste -d' ' <(git diff --cached --numstat 2>/dev/null|wc -l) <(git diff --numstat 2>/dev/null|wc -l) <(git ls-files --others --exclude-standard 2>/dev/null|wc -l)|tr -s ' ')
        ((''${s:-0}>0))&&GS="+$s";((''${m:-0}>0))&&GS="''${GS:+$GS }!$m";((''${u:-0}>0))&&GS="''${GS:+$GS }?$u";}
      TS=$((DUR_MS/1000));TH=$((TS/3600));TM=$(((TS%3600)/60));TSC=$((TS%60))
      ((TH>0))&&TMS="''${TH}h''${TM}m"||{ ((TM>0))&&TMS="''${TM}m''${TSC}s"||TMS="''${TSC}s";}
      TV=$((TH*34));((TV>80))&&TC=$cR||{ ((TV>50))&&TC=$cY||TC=$cG;}
      ((PCT>80))&&CC=$cR||{ ((PCT>50))&&CC=$cY||CC=$cG;}
      BAR="";f=$((PCT/10));((PCT>0&&f==0))&&f=1;((f>10))&&f=10
      for((i=0;i<f;i++));do BAR+="''${CC}▰";done;for((i=f;i<10;i++));do BAR+="''${D2}▱";done
      S="''${D1}│''${B1}" S2="''${D2}│''${B2}"
      _v(){ printf "%b" "$1"|sed $'s/\033\\[[0-9;]*m//g'|tr -d '\n'|LC_ALL=en_US.UTF-8 wc -m|tr -d ' ';}
      # Segment A: model+dir (L1) vs context bar (L2)
      A1=" ''${F1}''${B}''${TI} ''${MODEL}''${B1}  ''${F1}\xef\x81\xbb ''${DIR}''${B1} "
      A2=" ''${BAR} ''${CC}''${PCT}%''${B2}''${D2}/''${CTX_K}k "
      # Segment B: git (L1) vs time (L2)
      B1S=" ''${F1}\xee\x82\xa0 ''${BR}''${B1}";[ -n "$GS" ]&&B1S+=" ''${F1}''${GS}''${B1}"
      [ -z "$BR" ]&&B1S=""
      [ -n "$AGENT" ]&&B1S+="  ''${F1}''${AGENT}''${B1}"
      [ -n "$MODE" ]&&B1S+="  ''${F1}''${B}''${MODE}''${B1}"
      B1S+=" "
      B2S=" ''${TC}\xef\x80\x97 ''${TMS}''${B2} "
      # Segment C: S/D costs (L1) vs W/M costs (L2)
      C1=" ''${D1}S:''${F1}''${F_S}''${B1} ''${D1}D:''${F1}''${F_D}''${B1} "
      C2="";[ -f "$CF" ]&&C2=" ''${cM}W:''${F2}''${F_W} ''${cM}M:''${F2}''${F_M}''${B2} "
      # Measure and pad each segment pair
      WA1=$(_v "$A1");WA2=$(_v "$A2");WA=$((WA1>WA2?WA1:WA2))
      WB1=$(_v "$B1S");WB2=$(_v "$B2S");WB=$((WB1>WB2?WB1:WB2))
      WC1=$(_v "$C1");WC2=$(_v "$C2");WC=$((WC1>WC2?WC1:WC2))
      pad(){ (($1>0))&&printf '%*s' "$1" ""||:;}
      # Center each segment: split padding into left+right halves
      cx(){ _d=$(($1-$2));echo "$((_d/2)) $((_d-_d/2))";}
      read -r la1 ra1 < <(cx $WA $(_v "$A1"));read -r la2 ra2 < <(cx $WA $(_v "$A2"))
      read -r lb1 rb1 < <(cx $WB $(_v "$B1S"));read -r lb2 rb2 < <(cx $WB $(_v "$B2S"))
      read -r lc1 rc1 < <(cx $WC $(_v "$C1"));read -r lc2 rc2 < <(cx $WC $(_v "$C2"))
      L1="''${B1}$(pad $la1)''${A1}$(pad $ra1)''${S}$(pad $lb1)''${B1S}$(pad $rb1)''${S}$(pad $lc1)''${C1}$(pad $rc1)"
      L2="''${B2}$(pad $la2)''${A2}$(pad $ra2)''${S2}$(pad $lb2)''${B2S}$(pad $rb2)''${S2}$(pad $lc2)''${C2}$(pad $rc2)"
      printf '\033]1;%s\007' "''${DIR:-Claude}" >/dev/tty 2>/dev/null||true
      echo -e "''${L1}\033[K''${R}"
      echo -e "''${L2}\033[K''${R}"
    '';
  };

  # ---------------------------------------------------------------------------
  # Marketplace builder (was data/plugins/marketplace.nix)
  # ---------------------------------------------------------------------------
  claudeCodeMarketplace = let
    inherit (builtins) toJSON;
    inherit (lib) foldl' optionalAttrs mapAttrs mapAttrs' mapAttrsToList nameValuePair attrNames;
  in {
    # Main build function
    build = {
      name,
      owner,
      plugins,
      basePath ? ".config/claude",
      description ? "Personal Claude Code plugin marketplace",
      version ? "1.0.0",
    }:
    # Marketplace manifest
      {
        "${basePath}/.claude-plugin/marketplace.json" = {
          text = ({
            name,
            owner,
            plugins,
            description ? "Personal Claude Code plugin marketplace",
            version ? "1.0.0",
          }:
            toJSON {
              inherit name version;
              metadata = {
                inherit description;
                pluginRoot = "./plugins";
              };
              owner = {
                inherit (owner) name;
                email = owner.email or "";
              };
              plugins =
                mapAttrsToList (pluginName: plugin: {
                  name = pluginName;
                  source = "./plugins/${pluginName}";
                  inherit (plugin) description version;
                  author = plugin.author or owner;
                  strict = false; # marketplace entry serves as manifest
                })
                plugins;
            }) {inherit name owner plugins description version;};
        };
      }
      # All plugin files
      // foldl' (acc: pluginName:
        acc
        // (basePath: pluginName: plugin: let
          pluginPath = "${basePath}/plugins/${pluginName}";
          pluginHooks = plugin.hooks;
        in
          # plugin.json
          {
            "${pluginPath}/.claude-plugin/plugin.json" = {
              text =
                (name: plugin:
                  toJSON (
                    {
                      inherit name;
                      inherit (plugin) description version;
                      author = plugin.author or {};
                    }
                    // optionalAttrs (plugin ? hooks) {
                      hooks = "./hooks/hooks.json";
                    }
                    // optionalAttrs (plugin ? mcpServers) {
                      inherit (plugin) mcpServers;
                    }
                  ))
                pluginName
                plugin;
            };
          }
          # Commands
          // optionalAttrs (plugin ? commands) (
            mapAttrs' (cmdName: cmdContent:
              nameValuePair "${pluginPath}/commands/${cmdName}.md" {
                text = cmdContent;
              })
            plugin.commands
          )
          # Hooks configuration
          // optionalAttrs (plugin ? hooks && pluginHooks != {}) {
            "${pluginPath}/hooks/hooks.json" = {
              text = (hooks:
                toJSON {
                  hooks =
                    mapAttrs (
                      _: eventHooks:
                        map (hook: {
                          inherit (hook) matcher;
                          hooks =
                            map (h: {
                              type = h.type or "command";
                              inherit (h) command;
                            })
                            hook.hooks;
                        })
                        eventHooks
                    )
                    hooks;
                })
              pluginHooks.config;
            };
          }
          # Hook scripts
          // optionalAttrs (plugin ? hooks.scripts) (
            mapAttrs' (scriptName: scriptContent:
              nameValuePair "${pluginPath}/hooks/scripts/${scriptName}" {
                text = scriptContent;
                executable = true;
              })
            pluginHooks.scripts
          )
          # Instructions (CLAUDE.md at plugin root)
          // optionalAttrs (plugin ? instructions) {
            "${pluginPath}/CLAUDE.md" = {
              text = plugin.instructions;
            };
          }
          # Agents
          // optionalAttrs (plugin ? agents) (
            mapAttrs' (agentName: agentContent:
              nameValuePair "${pluginPath}/agents/${agentName}.md" {
                text = agentContent;
              })
            plugin.agents
          )
          # Skills
          // optionalAttrs (plugin ? skills) (
            let
              pluginSkills = plugin.skills;
            in
              foldl' (
                acc: skillName: let
                  skill = pluginSkills."${skillName}";
                  inherit (builtins) isAttrs;
                in
                  acc
                  // {
                    "${pluginPath}/skills/${skillName}/SKILL.md" = {
                      text =
                        if isAttrs skill
                        then skill.skill
                        else skill;
                    };
                  }
                  // optionalAttrs (isAttrs skill && skill ? interface) {
                    "${pluginPath}/skills/${skillName}/agents/openai.yaml" = {
                      generator = lib.generators.toYAML {};
                      value = {
                        inherit (skill) interface;
                      };
                    };
                  }
              ) {} (attrNames pluginSkills)
          )
          # Data files (arbitrary files at plugin root)
          // optionalAttrs (plugin ? dataFiles) (
            mapAttrs' (fileName: fileContent:
              nameValuePair "${pluginPath}/${fileName}" {
                text = fileContent;
              })
            plugin.dataFiles
          ))
        basePath
        pluginName
        plugins."${pluginName}")
      {} (attrNames plugins);
  };

  # ---------------------------------------------------------------------------
  # Plugin definitions (was data/plugins/*.nix)
  # ---------------------------------------------------------------------------

  # Codex MCP reminder command (shared between SessionStart and UserPromptSubmit hooks)
  codexReminderCommand = ''    printf '%s\n' '<system-reminder>
    Use Codex MCP when seeking reviews or second opinions.
    </system-reminder>''''';

  # Instructify dispatch script
  instructifyDispatchSh = ''
    #!/usr/bin/env bash
    # instructify-dispatch.sh — Config-driven hook instruction injector
    # Reads instructions.json and injects matching system reminders for any hook event.

    set -euo pipefail

    # Read all of stdin
    input=$(cat)

    # Check for jq
    if ! command -v jq &>/dev/null; then
      echo '{"error":"jq is required but not installed"}' >&2
      exit 1
    fi

    # Extract hook event name
    event=$(echo "$input" | jq -r '.hook_event_name // empty')
    if [[ -z "$event" ]]; then
      exit 0
    fi

    # Resolve instructions.json path
    plugin_root="''${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "''${BASH_SOURCE[0]}")/.." && pwd)}"
    config="$plugin_root/instructions.json"

    if [[ ! -f "$config" ]]; then
      exit 0
    fi

    # Extract the filterable value from the event data depending on event type
    get_filter_value() {
      case "$event" in
        SessionStart)
          echo "$input" | jq -r '.source // empty'
          ;;
        PreToolUse|PostToolUse|PostToolUseFailure|PermissionRequest)
          echo "$input" | jq -r '.tool_name // empty'
          ;;
        Notification)
          echo "$input" | jq -r '.type // empty'
          ;;
        SubagentStart|SubagentStop)
          echo "$input" | jq -r '.agent_type // empty'
          ;;
        PreCompact)
          echo "$input" | jq -r '.trigger // empty'
          ;;
        SessionEnd)
          echo "$input" | jq -r '.reason // empty'
          ;;
        *)
          echo ""
          ;;
      esac
    }

    filter_value=$(get_filter_value)

    # Collect instructions from all named rules where:
    #   - the current event is in the rule's "events" array
    #   - if the rule has a "matcher", the filter_value matches it
    #   - the rule is not explicitly disabled (enabled != false)
    matched_json=$(jq --arg evt "$event" --arg fv "$filter_value" '
      [
        to_entries[] |
        .value |
        select(type == "object") |
        select((.enabled == false) | not) |
        select(has("events") and (.events | type == "array")) |
        select(.events | index($evt)) |
        if (has("matcher") and (.matcher | type == "string")) then
          .matcher as $m | select(try ($fv | test($m)) catch false)
        else
          .
        end |
        select(has("instruction") and (.instruction | type == "string")) |
        .instruction
      ]
    ' "$config" 2>/dev/null) || true

    # Check if any instructions matched
    count=$(echo "$matched_json" | jq 'length' 2>/dev/null) || count=0
    if [[ "$count" -eq 0 || -z "$matched_json" ]]; then
      case "$event" in
        SessionStart|Notification)
          echo ""
          ;;
        Stop)
          exit 0
          ;;
        *)
          echo '{"decision":"approve","reason":""}'
          ;;
      esac
      exit 0
    fi

    # Wrap each matched instruction in system-reminder tags
    wrapped=""
    for i in $(seq 0 $((count - 1))); do
      instruction=$(echo "$matched_json" | jq -r ".[$i]")
      wrapped="''${wrapped}<system-reminder>
    ''${instruction}
    </system-reminder>
    "
    done
    # Trim trailing newline
    wrapped="''${wrapped%$'\n'}"

    # Output the correct JSON format per event type
    case "$event" in
      SessionStart|Notification)
        # Plain text output
        echo "$wrapped"
        ;;
      Stop)
        # Stop events use decision + reason
        reason=$(echo "$wrapped" | jq -Rs .)
        echo "{\"decision\":\"approve\",\"reason\":''${reason}}"
        ;;
      *)
        # All other events use hookSpecificOutput.additionalContext
        context=$(echo "$wrapped" | jq -Rs .)
        echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"''${event}\",\"additionalContext\":''${context}}}"
        ;;
    esac

    exit 0
  '';

  claudeCodePlugins = {
    agent-slack = {
      name = "agent-slack";
      version = "1.0.0";
      description = "Expose the local agent-slack CLI as an installable skill";
      author = {
        name = "y0usaf";
      };
      skills = {
        agent-slack = import ../../../lib/ai/skills/agent-slack.nix;
      };
    };

    audio-notify = {
      name = "audio-notify";
      version = "1.0.0";
      description = "Audio notifications for Claude Code events";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "bun \${CLAUDE_PLUGIN_ROOT}/hooks/scripts/completion-sound.ts";
                  async = true;
                }
              ];
            }
          ];
        };
        scripts = {
          "completion-sound.ts" = ''
            #!/usr/bin/env bun
            import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
            import { join } from "path";
            import { exec } from "child_process";

            const LOGS_DIR = join(process.env.HOME || "/tmp", ".claude", "logs");
            const SOUNDS_DIR = join(process.env.HOME || "/tmp", ".claude");

            if (!existsSync(LOGS_DIR)) {
              mkdirSync(LOGS_DIR, { recursive: true });
            }

            function readStdin(): Promise<string> {
              return new Promise((resolve, reject) => {
                let input = "";
                process.stdin.setEncoding("utf8");
                process.stdin.on("data", (chunk) => (input += chunk));
                process.stdin.on("end", () => resolve(input));
                process.stdin.on("error", reject);
                setTimeout(() => resolve(input), 5000);
              });
            }

            function parseJson<T>(input: string): T | null {
              try {
                return JSON.parse(input) as T;
              } catch {
                return null;
              }
            }

            function appendToLog(logFileName: string, data: Record<string, unknown>): void {
              const logFile = join(LOGS_DIR, logFileName);
              let logs: Record<string, unknown>[] = [];

              if (existsSync(logFile)) {
                try {
                  logs = JSON.parse(readFileSync(logFile, "utf8"));
                  if (!Array.isArray(logs)) logs = [];
                } catch {
                  logs = [];
                }
              }

              logs.push({ timestamp: new Date().toISOString(), ...data });
              if (logs.length > 1000) logs = logs.slice(-1000);
              writeFileSync(logFile, JSON.stringify(logs, null, 2));
            }

            function playSound(soundFileName: string, volume = 1.0): Promise<void> {
              return new Promise((resolve) => {
                if (process.env.CLAUDE_CODE_HEADLESS === "1") {
                  resolve();
                  return;
                }

                const soundFile = join(SOUNDS_DIR, soundFileName);
                if (!existsSync(soundFile)) {
                  resolve();
                  return;
                }

                const pulseVolume = Math.round(volume * 65536);
                const cmd = `pw-play --volume=''${volume} "''${soundFile}" 2>/dev/null || paplay --volume=''${pulseVolume} "''${soundFile}" 2>/dev/null || aplay -q "''${soundFile}" 2>/dev/null`;

                exec(cmd, () => resolve());
              });
            }

            interface HookData {
              stop_hook_active?: boolean;
              transcript_path?: string;
              [key: string]: unknown;
            }

            async function main() {
              try {
                const input = await readStdin();
                const data = parseJson<HookData>(input);

                if (!data) {
                  process.exit(0);
                }

                appendToLog("stop.json", data);
                await playSound("on-agent-complete.wav", 0.25);
                process.exit(0);
              } catch {
                process.exit(0);
              }
            }

            main();
          '';
        };
      };
    };

    codex-mcp = {
      name = "codex-mcp";
      version = "1.0.0";
      description = "OpenAI Codex MCP server for second opinions and reasoning";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          SessionStart = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = codexReminderCommand;
                }
              ];
            }
          ];
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = codexReminderCommand;
                }
              ];
            }
          ];
        };
      };
      mcpServers = {
        codex = {
          command = "bunx";
          args = [
            "--bun"
            "@openai/codex"
            "mcp-server"
            "-c"
            "model=gpt-5.2-codex"
            "-c"
            "model_reasoning_effort=high"
          ];
        };
      };
    };

    collab-flow = {
      name = "collab-flow";
      version = "1.0.0";
      description = "Reminders to use AskUserQuestion for collaboration";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "echo '<system-reminder>MANDATORY: Use AskUserQuestion before proceeding.</system-reminder>'";
                }
              ];
            }
          ];
        };
      };
    };

    gh = {
      name = "gh";
      version = "1.0.0";
      description = "Expose the installed GitHub CLI as an installable skill";
      author = {
        name = "y0usaf";
      };
      skills = {
        gh = import ../../../lib/ai/skills/gh.nix;
      };
    };

    instructify = {
      name = "instructify";
      version = "1.1.0";
      description = "Config-driven hook instruction injector - maps hook events to system reminders";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = builtins.listToAttrs (map (event: {
            name = event;
            value = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/instructify-dispatch.sh";
                  }
                ];
              }
            ];
          })
          [
            "SessionStart"
            "UserPromptSubmit"
            "PreToolUse"
            "PermissionRequest"
            "PostToolUse"
            "PostToolUseFailure"
            "Notification"
            "SubagentStart"
            "SubagentStop"
            "Stop"
            "PreCompact"
            "SessionEnd"
          ]);
        scripts = {
          "instructify-dispatch.sh" = instructifyDispatchSh;
        };
      };
      dataFiles = {
        "instructions.json" = builtins.toJSON {
          agentic-terminal-instruct = {
            events = ["UserPromptSubmit"];
            instruction = ''
              MANDATORY: If you are about to tell the user to run a terminal command that you can run agentically, run it yourself instead.
              Only ask the user to run commands when execution is blocked by missing permissions, missing credentials, unavailable local environment, or explicit user preference.'';
          };
        };
      };
    };

    instruct-self-review = {
      name = "instruct-self-review";
      version = "1.0.0";
      description = "Stop hook that instructs to review all file changes with critical minimalism principles";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/self-review.sh";
                }
              ];
            }
          ];
        };
        scripts = {
          "self-review.sh" = ''
            #!/usr/bin/env bash
            # Read stdin to get hook event data
            # Stop hooks need JSON format with additionalContext field
            input=$(cat)

            review_context="<system-reminder>\nCRITICAL REVIEW REQUIRED: Review all file changes that were just made, being critical and following these 2 rules:\n\n1. **The best code is no code** - Question whether each change is necessary. Every line of code is a liability.\n\n2. **The best code is code that can be deleted** - Favor minimal, removable solutions. Avoid adding features or abstractions that might not be used. If code can't be easily deleted later, it's probably too coupled or over-engineered.\n\nAsk yourself:\n- Did I add code that could be removed without breaking functionality?\n- Did I introduce abstractions when a simple solution would suffice?\n- Are there any lines that don't earn their keep?\n- Could the implementation be simpler or more straightforward?\n- Did I add error handling, validation, or features for edge cases that don't exist yet?\n\nRefactor aggressively toward minimalism.\n</system-reminder>"

            echo "$review_context" | jq -Rs '{decision:"approve",reason:"",hookSpecificOutput:{additionalContext:.}}'
            exit 0
          '';
        };
      };
    };

    linear-cli = {
      name = "linear-cli";
      version = "1.0.0";
      description = "Expose the schpet Linear CLI via bunx as an installable skill";
      author = {
        name = "y0usaf";
      };
      skills = {
        linear-cli = import ../../../lib/ai/skills/linear-cli.nix;
      };
    };

    teams-instruct = {
      name = "teams-instruct";
      version = "1.0.0";
      description = "Reminders to always use agent teams for task parallelization";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = ''
                    cat <<'EOF'
                    <system-reminder>
                    MANDATORY: Use Agent Teams for ALL tasks. Never work alone when teammates can parallelize the effort.

                    Workflow:
                    1. TeamCreate -> create a team
                    2. TaskCreate -> break work into subtasks
                    3. Task tool (with team_name and name params) -> spawn teammates
                    4. TaskUpdate (with owner param) -> assign tasks to teammates
                    5. SendMessage type: "shutdown_request" -> when all work is complete
                    6. TeamDelete -> clean up

                    Always break work into parallel subtasks and delegate to teammates.
                    </system-reminder>
                    EOF
                  '';
                }
              ];
            }
          ];
        };
      };
    };

    todowrite-instruct = {
      name = "todowrite-instruct";
      version = "1.0.0";
      description = "Reminders to use TodoWrite for task tracking";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "echo '<system-reminder>MANDATORY: Use TaskCreate before proceeding.</system-reminder>'";
                }
              ];
            }
          ];
        };
      };
    };

    tool-tracker = {
      name = "tool-tracker";
      version = "1.0.0";
      description = "Tracks tool usage per session for analysis";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          PreToolUse = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "bun \${CLAUDE_PLUGIN_ROOT}/hooks/scripts/tool-tracker.ts";
                  async = true;
                }
              ];
            }
          ];
        };
        scripts = {
          "tool-tracker.ts" = ''
            #!/usr/bin/env bun
            import { writeFileSync, existsSync, mkdirSync, readFileSync } from "fs";
            import { join } from "path";

            function readStdin(): Promise<string> {
              return new Promise((resolve, reject) => {
                let input = "";
                process.stdin.setEncoding("utf8");
                process.stdin.on("data", (chunk) => (input += chunk));
                process.stdin.on("end", () => resolve(input));
                process.stdin.on("error", reject);
                setTimeout(() => resolve(input), 5000);
              });
            }

            function parseJson<T>(input: string): T | null {
              try {
                return JSON.parse(input) as T;
              } catch {
                return null;
              }
            }

            interface ToolUseData {
              tool_name: string;
              tool_input?: Record<string, unknown>;
              session_id: string;
            }

            const CACHE_DIR = "/tmp/claude-tool-cache";

            async function main() {
              const input = await readStdin();
              const data = parseJson<ToolUseData>(input);

              if (!data || !data.tool_name || !data.session_id) {
                process.exit(0);
              }

              const sessionDir = join(CACHE_DIR, data.session_id);
              if (!existsSync(sessionDir)) {
                mkdirSync(sessionDir, { recursive: true });
              }

              const toolsFile = join(sessionDir, "tools-used.json");
              let toolsUsed: { tool: string; timestamp: string; input?: Record<string, unknown> }[] = [];

              if (existsSync(toolsFile)) {
                try {
                  toolsUsed = JSON.parse(readFileSync(toolsFile, "utf8"));
                } catch {
                  toolsUsed = [];
                }
              }

              toolsUsed.push({
                tool: data.tool_name,
                timestamp: new Date().toISOString(),
                input: data.tool_input,
              });

              writeFileSync(toolsFile, JSON.stringify(toolsUsed, null, 2));
              process.exit(0);
            }

            main().catch(() => process.exit(0));
          '';
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Config assembly
  # ---------------------------------------------------------------------------
  claudeCodeCfg = user.dev.claude-code;

  claudeCodeSkillEnabled = skillName:
    attrByPath ["user" "dev" "claude-code" "skills" skillName "enable"] true config;

  settingsJson = {
    inherit (claudeCodeCfg) model effortLevel extraKnownMarketplaces;
    inherit
      (ccSettings)
      includeCoAuthoredBy
      permissions
      promptSuggestionEnabled
      skipDangerousModePermissionPrompt
      ;
    env =
      ccSettings.env
      // {
        CLAUDE_CODE_SUBAGENT_MODEL = claudeCodeCfg.subagentModel;
      };
    statusLine = {
      type = "command";
      command = "${statuslineScript}/bin/statusline";
    };
    enabledPlugins = filterAttrs (_: enabled: enabled) claudeCodeCfg.enabledPlugins;
  };
in {
  options.user.dev.claude-code = {
    enable = mkEnableOption "Claude Code development tools";

    model = mkOption {
      type = str;
      default = "opus";
      description = "Claude model to use";
    };

    subagentModel = mkOption {
      type = str;
      default = "opus";
      description = "Claude model to use for subagents";
    };

    effortLevel = mkOption {
      type = str;
      default = "high";
      description = "Claude Code effort level to use";
    };

    enabledPlugins = mkOption {
      type = attrsOf bool;
      default =
        {
          "audio-notify@y0usaf-marketplace" = true;
          "instructify@y0usaf-marketplace" = true;
          "purr@ai-eng-plugins" = true;
          "skillify@ai-eng-plugins" = true;
          "skills-framework@ai-eng-plugins" = true;
          "the-chopper@ai-eng-plugins" = true;
        }
        // optionalAttrs (ghEnabled && claudeCodeSkillEnabled "gh") {
          "gh@y0usaf-marketplace" = true;
        }
        // optionalAttrs (claudeCodeSkillEnabled "linear-cli") {
          "linear-cli@y0usaf-marketplace" = true;
        }
        // optionalAttrs (agentSlackEnabled && claudeCodeSkillEnabled "agent-slack") {
          "agent-slack@y0usaf-marketplace" = true;
        };
      description = ''
        Claude Code plugins keyed by `plugin@marketplace`.
        False values are omitted from the generated `settings.json`.
      '';
    };

    extraKnownMarketplaces = mkOption {
      type = attrsOf (attrsOf anything);
      default = {
        "y0usaf-marketplace" = {
          source = {
            source = "directory";
            path = "${config.user.homeDirectory}/.config/claude";
          };
        };
        "ai-eng-plugins" = {
          source = {
            source = "git";
            owner = "Cook-Unity";
            repo = "ai-eng-plugins";
            url = "git@github.com:Cook-Unity/ai-eng-plugins.git";
          };
        };
        "claude-code-plugins" = {
          source = {
            source = "github";
            repo = "anthropics/claude-code";
          };
        };
      };
      description = "Additional Claude Code plugin marketplaces.";
    };

    skills =
      mapAttrs (pluginName: _: {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to enable the `${pluginName}` Claude Code skill plugin.";
        };
      })
      (filterAttrs (_: plugin: plugin ? skills) claudeCodePlugins);
  };

  config = mkIf claudeCodeCfg.enable {
    environment.systemPackages =
      optionals (!config.programs.tweakcc.enable) [pkgs.claude-code]
      ++ [
        (pkgs.writeShellScriptBin "bunclaude" ''
          exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
        '')
      ];

    bayt.users."${user.name}".files =
      (claudeCodeMarketplace.build {
        name = "y0usaf-marketplace";
        owner = {
          name = "y0usaf";
          email = "";
        };
        plugins = claudeCodePlugins;
        basePath = ".config/claude";
        description = "Personal Claude Code plugin marketplace";
        version = "1.0.0";
      })
      // {
        ".claude/on-agent-need-attention.wav" = {
          source = ./assets/tuturu.ogg;
        };

        ".claude/on-agent-complete.wav" = {
          source = ./assets/tuturu.ogg;
        };

        ".claude/CLAUDE.md" = {
          text = claudeCodeInstructions;
        };

        ".claude/settings.json" = {
          generator = generators.toJSON {};
          value = settingsJson;
        };
      };

    programs.tweakcc = {
      enable = false;
      settings = {
        misc = {
          hideStartupBanner = true;
          expandThinkingBlocks = false;
        };
        claudeMdAltNames = ["AGENTS.md"];
      };
    };
  };
}
