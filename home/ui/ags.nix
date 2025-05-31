###############################################################################
# AGS v2 Module (Astal Framework)
# Installs AGS v2 as a regular package
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.ui.ags;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.ags = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 (Astal Framework)";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    # Install AGS CLI
    home.packages = with pkgs; [
      ags
    ];

    ###########################################################################
    # AGS v2 Configuration Files
    ###########################################################################
    xdg.configFile = {
      "ags/app.tsx".text = ''
        import { App, Astal, Gtk } from "astal/gtk3"
        import { Variable, exec, subprocess } from "astal"

        // ============================================================================
        // UTILITY FUNCTIONS
        // ============================================================================

        // Safe command execution helper for AGS v2
        function safeExec(command: string, defaultValue: string = 'N/A'): string {
            try {
                const result = exec(["bash", "-c", command]);
                return result.trim() || defaultValue;
            } catch (error) {
                console.log(`Failed to execute command: ''${command}`, error);
                return defaultValue;
            }
        }

        // Timer-based time updates (more efficient than polling)
        function setupTimeUpdates(currentTime: any, currentDate: any) {
            const updateTime = () => {
                currentTime.set(safeExec('date "+%H:%M:%S"'));
            };

            const updateDate = () => {
                currentDate.set(safeExec('date "+%d/%m/%y"'));
            };

            // Update immediately
            updateTime();
            updateDate();

            // Update time every second using setTimeout instead of polling
            const timeInterval = setInterval(updateTime, 1000);

            // Update date at midnight and then every 24 hours
            const now = new Date();
            const tomorrow = new Date(now);
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(0, 0, 0, 0);
            const msUntilMidnight = tomorrow.getTime() - now.getTime();

            setTimeout(() => {
                updateDate();
                // Then update every 24 hours
                setInterval(updateDate, 24 * 60 * 60 * 1000);
            }, msUntilMidnight);
        }

        // Event-driven package count monitoring
        function setupPackageMonitoring(packageCount: any) {
            const updatePackageCount = () => {
                const count = safeExec("which nix-store >/dev/null 2>&1 && nix-store -q --requisites /run/current-system/sw 2>/dev/null | wc -l || echo 'N/A'").trim();
                packageCount.set(count);
            };

            updatePackageCount();

            // Monitor for system rebuilds and package operations
            subprocess([
                "bash",
                "-c",
                `
                # Monitor for NixOS rebuilds and package changes
                while true; do
                    inotifywait -e modify,create,delete /nix/var/nix/profiles/system* 2>/dev/null || sleep 30
                    echo "package_change"
                done
                `
            ], (output: string) => {
                if (output.includes('package_change')) {
                    updatePackageCount();
                }
            });
        }

        // Helper functions for SystemStats component
        function padLabel(label: string, longestLabel: number): string {
            return label + ' '.repeat(longestLabel - label.length);
        }

        function horizontalBorder(char1: string, char2: string, char3: string, longestLabel: number): string {
            return char1 + "─".repeat(longestLabel + 4) + char3;
        }

        // Cache GPU availability check
        const hasNvidiaGpu = (() => {
            try {
                exec(["bash", "-c", "which nvidia-smi >/dev/null 2>&1"]);
                return true;
            } catch {
                return false;
            }
        })();

        // ============================================================================
        // STYLES
        // ============================================================================

        const styles = `
        /* Base font size */
        * {
            font-size: 14px;
            font-family: monospace;
        }

        /* System Stats Widget Styles */
        .system-stats-window {
            background: transparent;
        }

        .system-stats {
            background: transparent;
            padding: 0.5em;
            margin: 0.5em;
            font-family: monospace;
            font-size: 1rem;
        }

        .system-stats * {
            margin: 0;
            padding: 0;
            background: transparent;
            border: none;
            box-shadow: none;
            text-shadow:
                0.05rem 0 0.05rem #000000,
                -0.05rem 0 0.05rem #000000,
                0 0.05rem 0.05rem #000000,
                0 -0.05rem 0.05rem #000000,
                0.05rem 0.05rem 0.05rem #000000,
                -0.05rem 0.05rem 0.05rem #000000,
                0.05rem -0.05rem 0.05rem #000000,
                -0.05rem -0.05rem 0.05rem #000000;
            font-family: inherit;
            font-size: inherit;
            font-weight: inherit;
            color: inherit;
        }

        /* Rainbow color assignments */
        .stats-time { color: #ff0000; }     /* Red */
        .stats-date { color: #ff8800; }     /* Orange */
        .stats-shell { color: #ffff00; }    /* Yellow */
        .stats-uptime { color: #00ff00; }   /* Green */
        .stats-pkgs { color: #00ff88; }     /* Blue-Green */
        .stats-memory { color: #00ffff; }   /* Cyan */
        .stats-cpu { color: #0088ff; }      /* Blue */
        .stats-gpu { color: #ff00ff; }      /* Magenta */
        .stats-colors { color: #ffffff; }   /* White */
        .stats-white { color: #ffffff; }    /* White */
        .stats-red { color: #ff0000; }
        .stats-orange { color: #ff8800; }
        .stats-yellow { color: #ffff00; }
        .stats-green { color: #00ff00; }
        .stats-blue-green { color: #00ff88; }
        .stats-cyan { color: #00ffff; }
        .stats-blue { color: #0088ff; }
        .stats-magenta { color: #ff00ff; }

        /* Workspaces Widget Styles */
        .workspaces-top, .workspaces-bottom {
            background: transparent;
        }

        .workspaces {
            background: transparent;
            margin: 0;
            padding: 0;
        }

        .workspaces *,
        .workspaces {
            margin: 0;
            padding: 0;
            background: transparent;
            border: none;
            box-shadow: none;
            color: white;
        }

        .workspace-btn {
            margin: 0;
            padding: 0;
            background-color: #222;
            border-radius: 0;
            min-width: 20px;
            min-height: 20px;
        }

        .workspace-btn label {
            background: transparent;
            color: rgba(255, 255, 255, 0.4);
            font-size: 0.8rem;
            padding: 0.25em;
        }

        .workspace-btn.active label {
            color: rgba(255, 255, 255, 1.0);
        }

        .workspace-btn.occupied label {
            color: rgba(255, 255, 255, 0.8);
        }

        .workspace-btn.inactive label {
            color: rgba(255, 255, 255, 0.5);
        }

        .workspace-btn.urgent label {
            color: #ff5555;
        }
        `

        // ============================================================================
        // SYSTEM STATS MODULE
        // ============================================================================

        // Show/hide control variables
        const systemStatsVisible = Variable(true);
        const systemStatsLayer = Variable(Astal.Layer.BOTTOM);

        // System monitoring variables with optimized polling intervals
        const cpuTemp = Variable('N/A').poll(250, () => {
            return safeExec("sensors 2>/dev/null | grep -E 'Tctl|Package id 0' | head -1 | awk '{print $2}' | sed 's/+//' || echo 'N/A'");
        });

        const gpuTemp = Variable('N/A').poll(250, () => {
            if (!hasNvidiaGpu) return 'N/A';
            const temp = safeExec("nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A'");
            return temp !== "N/A" && temp !== "" ? temp + "C" : "N/A";
        });

        const memoryInfo = Variable({ used: 'N/A', total: 'N/A' }).poll(2000, () => {
            try {
                const output = exec(["bash", "-c", "free -h | grep '^Mem:' | awk '{print $3 \"/\" $2}'"]);
                const parts = output.trim().split('/');
                return { used: parts[0] || 'N/A', total: parts[1] || 'N/A' };
            } catch {
                return { used: 'N/A', total: 'N/A' };
            }
        });

        const uptime = Variable('N/A').poll(60000, () => {
            return safeExec("uptime | sed 's/.*up *//' | sed 's/,.*user.*//' | sed 's/^ *//' | sed 's/ *$//' | sed 's/ day/d/' | sed 's/ days/d/'").trim();
        });

        // Timer-based time updates
        const currentTime = Variable('00:00:00');
        const currentDate = Variable('00/00/00');

        // Event-driven package count
        const packageCount = Variable('N/A');

        // Shell name never changes during session - set once
        const shellName = Variable(safeExec("basename \"$SHELL\""));

        // Initialize monitoring
        setupTimeUpdates(currentTime, currentDate);
        setupPackageMonitoring(packageCount);

        // Static data for SystemStats component (moved outside to prevent recreation)
        const statsLabels = ['time', 'date', 'shell', 'uptime', 'pkgs', 'memory', 'cpu', 'gpu', 'colors'];
        const longestLabel = Math.max(...statsLabels.map(l => l.length));

        // System Stats Widget Component
        function SystemStats() {
            return <window
                className="system-stats-window"
                layer={systemStatsLayer()}
                exclusivity={Astal.Exclusivity.IGNORE}
                visible={systemStatsVisible()}
                application={App}>
                <box className="system-stats" vertical>
                    {/* NixOS Logo */}
                    <label
                        className="stats-white"
                        label="   _  ___      ____  ____&#10;  / |/ (_)_ __/ __ \/ __/&#10; /    / /\ \ / /_/ /\ \&#10;/_/|_/_//_\_\\____/___/"
                    />

                    {/* Top border */}
                    <label
                        className="stats-white"
                        halign={Gtk.Align.START}
                        label={horizontalBorder("╭", "─", "╮", longestLabel)}
                    />

                    {/* Stats rows */}
                    {statsLabels.map(currentLabel =>
                        <box key={currentLabel}>
                            <label className="stats-white" halign={Gtk.Align.START} label="│ " />
                            <label className={`stats-''${currentLabel}`} halign={Gtk.Align.START} label="• " />
                            <label className="stats-white" halign={Gtk.Align.START} label={`''${padLabel(currentLabel, longestLabel)} │ `} />
                            <label
                                className={`stats-''${currentLabel}`}
                                halign={Gtk.Align.START}
                                label={(() => {
                                    switch(currentLabel) {
                                        case 'time': return currentTime();
                                        case 'date': return currentDate();
                                        case 'shell': return shellName();
                                        case 'uptime': return uptime();
                                        case 'pkgs': return packageCount();
                                        case 'memory': return `''${memoryInfo.get().used}/''${memoryInfo.get().total}`;
                                        case 'cpu': return cpuTemp();
                                        case 'gpu': return gpuTemp();
                                        case 'colors': return "";
                                        default: return "";
                                    }
                                })()}
                            />
                            {/* Color dots for colors row */}
                            {currentLabel === 'colors' && [
                                <label key="red" className="stats-red" label="• " />,
                                <label key="orange" className="stats-orange" label="• " />,
                                <label key="yellow" className="stats-yellow" label="• " />,
                                <label key="green" className="stats-green" label="• " />,
                                <label key="blue-green" className="stats-blue-green" label="• " />,
                                <label key="cyan" className="stats-cyan" label="• " />,
                                <label key="blue" className="stats-blue" label="• " />,
                                <label key="magenta" className="stats-magenta" label="• " />,
                                <label key="white" className="stats-white" label="• " />
                            ]}
                        </box>
                    )}

                    {/* Bottom border */}
                    <label
                        className="stats-white"
                        halign={Gtk.Align.START}
                        label={horizontalBorder("╰", "─", "╯", longestLabel)}
                    />
                </box>
            </window>
        }

        // ============================================================================
        // WORKSPACES MODULE
        // ============================================================================

        // Show/hide control variable
        const workspacesVisible = Variable(true);

        // Hyprland workspace management with real-time events
        const workspaces = Variable<any[]>([]);
        const activeWorkspace = Variable<number>(1);

        // Create a single derived variable for workspace state to optimize subscriptions
        const workspaceState = Variable.derive([workspaces, activeWorkspace], (ws, active) => ({
            workspaces: ws,
            activeWorkspace: active
        }));

        // Helper function to switch workspace using hyprctl
        function switchWorkspace(workspaceId: number) {
            try {
                exec(["hyprctl", "dispatch", "workspace", workspaceId.toString()]);
            } catch (error) {
                console.error("Failed to switch workspace:", error);
            }
        }

        // Initialize workspace data
        function initializeWorkspaces() {
            try {
                const output = exec(["bash", "-c", "hyprctl workspaces -j 2>/dev/null || echo '[]'"]);
                workspaces.set(JSON.parse(output));
            } catch {
                workspaces.set([]);
            }

            try {
                const output = exec(["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null || echo '{\"id\":1}'"]);
                const parsed = JSON.parse(output);
                activeWorkspace.set(parsed.id || 1);
            } catch {
                activeWorkspace.set(1);
            }
        }

        // Update workspace list when needed
        function updateWorkspaceList() {
            try {
                const output = exec(["bash", "-c", "hyprctl workspaces -j 2>/dev/null || echo '[]'"]);
                workspaces.set(JSON.parse(output));
            } catch {
                // Keep existing workspaces if update fails
            }
        }

        // Set up real-time Hyprland event monitoring
        function setupHyprlandEvents() {
            const hyprlandSignature = exec(["bash", "-c", "echo $HYPRLAND_INSTANCE_SIGNATURE"]).trim();
            if (!hyprlandSignature) {
                console.error("HYPRLAND_INSTANCE_SIGNATURE not found - not running under Hyprland");
                return;
            }

            // Get current user ID dynamically for portability
            const userId = exec(["bash", "-c", "id -u"]).trim();
            const socketPath = `/run/user/''${userId}/hypr/''${hyprlandSignature}/.socket2.sock`;

            // Real-time event monitoring using nc
            subprocess([
                "bash",
                "-c",
                `nc -U "''${socketPath}" 2>/dev/null || { echo "Failed to connect to Hyprland socket"; exit 1; }`
            ], (output) => {
                const lines = output.split('\\n').filter(line => line.trim());

                for (const line of lines) {
                    if (line.startsWith('workspace>>')) {
                        // Active workspace changed
                        const workspaceId = parseInt(line.split('>>')[1]) || 1;
                        activeWorkspace.set(workspaceId);
                    }
                    else if (line.startsWith('createworkspace>>')) {
                        // New workspace created
                        updateWorkspaceList();
                    }
                    else if (line.startsWith('destroyworkspace>>')) {
                        // Workspace destroyed
                        updateWorkspaceList();
                    }
                    else if (line.startsWith('openwindow>>') || line.startsWith('closewindow>>')) {
                        // Window opened/closed - might affect workspace occupancy
                        updateWorkspaceList();
                    }
                }
            });
        }

        // Initialize workspaces and start event monitoring
        initializeWorkspaces();
        setupHyprlandEvents();

        // Workspaces Widget Component
        function WorkspacesWidget(position: 'top' | 'bottom') {
            const anchor = position === 'top'
                ? Astal.WindowAnchor.TOP
                : Astal.WindowAnchor.BOTTOM;

            // Create workspace buttons (1-10 like in v1 config)
            const workspaceButtons = Array.from({ length: 10 }, (_, i) => {
                const workspaceId = i + 1;

                return <button
                    key={workspaceId}
                    className="workspace-btn"
                    onClicked={() => {
                        switchWorkspace(workspaceId);
                    }}
                    setup={(self) => {
                        // Function to update button state
                        const updateButton = () => {
                            const state = workspaceState.get();
                            const ws = state.workspaces;
                            const active = state.activeWorkspace;

                            const isActive = active === workspaceId;
                            const isOccupied = Array.isArray(ws) && ws.some((workspace: any) =>
                                workspace.id === workspaceId && workspace.windows > 0
                            );

                            // Show button if it's active or occupied, or if it's workspace 1 (always show)
                            self.visible = isActive || isOccupied || workspaceId === 1;

                            // Update CSS classes
                            self.className = `workspace-btn ''${isActive ? "active" : ""} ''${isOccupied && !isActive ? "occupied" : ""}`.trim();
                        };

                        // Initial update
                        updateButton();

                        // Subscribe to single workspace state variable instead of two separate ones
                        workspaceState.subscribe(updateButton);
                    }}>
                    <label label={workspaceId.toString()} />
                </button>
            });

            return <window
                className={`workspaces-''${position}`}
                layer={Astal.Layer.OVERLAY}
                exclusivity={Astal.Exclusivity.IGNORE}
                anchor={anchor}
                visible={workspacesVisible()}
                application={App}>
                <box className="workspaces">
                    {workspaceButtons}
                </box>
            </window>
        }

        // ============================================================================
        // MAIN APPLICATION
        // ============================================================================

        // Main app configuration
        App.start({
            css: styles,
            requestHandler(request: string, ...args: any[]) {
                switch (request) {
                    case "showStats":
                        systemStatsVisible.set(true);
                        systemStatsLayer.set(Astal.Layer.TOP);
                        return "Stats shown";
                    case "hideStats":
                        systemStatsLayer.set(Astal.Layer.BOTTOM);
                        return "Stats hidden";
                    case "toggleStats":
                        if (systemStatsLayer.get() === Astal.Layer.TOP) {
                            systemStatsLayer.set(Astal.Layer.BOTTOM);
                        } else {
                            systemStatsVisible.set(true);
                            systemStatsLayer.set(Astal.Layer.TOP);
                        }
                        return "Stats toggled";
                    case "showWorkspaces":
                        workspacesVisible.set(true);
                        return "Workspaces shown";
                    case "hideWorkspaces":
                        workspacesVisible.set(false);
                        return "Workspaces hidden";
                    case "toggleWorkspaces":
                        workspacesVisible.set(!workspacesVisible.get());
                        return "Workspaces toggled";
                    default:
                        return `Unknown request: ''${request}`;
                }
            },
            main() {
                // Create system stats window
                SystemStats();

                // Create workspace widgets
                WorkspacesWidget('top');
                WorkspacesWidget('bottom');
            },
        })
      '';

      "ags/tsconfig.json".text = ''
        {
          "compilerOptions": {
            "target": "ES2022",
            "module": "ES2022",
            "lib": ["ES2022"],
            "allowJs": true,
            "strict": true,
            "esModuleInterop": true,
            "skipLibCheck": true,
            "forceConsistentCasingInFileNames": true,
            "moduleResolution": "node",
            "jsx": "react-jsx",
            "jsxImportSource": "astal/gtk3/jsx-runtime"
          },
          "include": ["**/*.ts", "**/*.tsx"],
          "exclude": ["node_modules"]
        }
      '';
    };
  };
}
