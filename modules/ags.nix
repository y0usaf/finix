{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  ##########################################
  # Global Configuration & Shared Utils
  ##########################################
  shared = {
    shadowSize = "0.05rem";
    shadowRadius = "0.05rem";
    shadowColor = "#000000";
    repetitionCount = 4;
    colors = {
      red = "#ff0000";
      orange = "#ff8800";
      yellow = "#ffff00";
      green = "#00ff00";
      blueGreen = "#00ff88";
      cyan = "#00ffff";
      blue = "#0088ff";
      magenta = "#ff00ff";
      white = "#ffffff";
      darkBg = "#222222";
    };
  };

  # Configure which system stats modules are shown.
  # Change this list to enable/disable/reorder modules.
  # Valid entries: "time", "date", "shell", "uptime", "pkgs", "memory", "cpu", "gpu", "colors"
  systemStatsModules = ["time" "date" "shell" "uptime" "pkgs" "memory" "cpu" "gpu" "colors"];

  shadowOffsets = [
    "${shared.shadowSize} 0 ${shared.shadowRadius} ${shared.shadowColor}"
    "-${shared.shadowSize} 0 ${shared.shadowRadius} ${shared.shadowColor}"
    "0 ${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
    "0 -${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
    "${shared.shadowSize} ${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
    "-${shared.shadowSize} ${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
    "${shared.shadowSize} -${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
    "-${shared.shadowSize} -${shared.shadowSize} ${shared.shadowRadius} ${shared.shadowColor}"
  ];
  repeatedShadow =
    lib.concatStringsSep ",\n"
    (lib.concatLists (lib.genList (i: shadowOffsets) shared.repetitionCount));

  # CSS resets shared by widgets
  baseReset = ''
    margin: 0;
    padding: 0;
    background: none;
    border: none;
    box-shadow: none;
  '';
  systemStatsReset =
    baseReset
    + ''
      text-shadow: ${repeatedShadow};
      font-family: inherit;
      font-size: inherit;
      font-weight: inherit;
      color: inherit;
    '';
  workspacesReset =
    baseReset
    + ''
      color: white;
    '';

  ##########################################
  # AGS MAIN APP CONFIGURATION (JS)
  ##########################################
  configJS = ''
    import App from 'resource:///com/github/Aylur/ags/app.js';
    import { systemStatsConfig } from './system-stats.js';
    import { workspacesConfig } from './workspaces.js';

    App.config({
        style: App.configDir + "/style.css",
        windows: [
            systemStatsConfig.window,
            ...workspacesConfig.windows,
        ],
    });

    Object.assign(globalThis, {
        ...systemStatsConfig.profile,
        ...workspacesConfig.profile,
    });
  '';

  ##########################################
  # AGS STYLE CSS
  ##########################################
  styleCSS = ''
    html {
      font-size: ${toString profile.baseFontSize}px;
    }

    /* Global reset for both widgets */
    .system-stats *, .workspaces * {
        ${systemStatsReset}
    }

    /* -------------------- System Stats Styles -------------------- */
    .system-stats {
        text-shadow: 1pt 1pt 1pt rgba(0,0,0,0.5);
        font-size: 1rem;
        margin: 0.5em;
    }
    .system-stats label {
        margin: 0;
        padding: 0;
    }
    .stats-time { color: ${shared.colors.red}; }
    .stats-date { color: ${shared.colors.orange}; }
    .stats-shell { color: ${shared.colors.yellow}; }
    .stats-uptime { color: ${shared.colors.green}; }
    .stats-pkgs { color: ${shared.colors.blueGreen}; }
    .stats-memory { color: ${shared.colors.cyan}; }
    .stats-cpu { color: ${shared.colors.blue}; }
    .stats-gpu { color: ${shared.colors.magenta}; }
    .stats-colors { color: ${shared.colors.white}; }

    /* -------------------- Workspaces Widget Styles -------------------- */
    .workspaces, .workspaces * {
        ${workspacesReset}
    }
    .workspace-btn {
        background-color: ${shared.colors.darkBg};
        border-radius: 0.2rem;
        margin: 0 0.1rem;
        transition: all 0.2s ease;
    }
    .workspace-btn label {
        background: none;
        color: rgba(255, 255, 255, 0.4);
        font-size: 0.8rem;
        padding: 0.25em 0.5em;
    }
    .workspace-btn.active {
        background-color: rgba(255, 255, 255, 0.2);
    }
    .workspace-btn.active label {
        color: rgba(255, 255, 255, 1.0);
    }
    .workspace-btn.occupied:not(.active) {
        background-color: rgba(255, 255, 255, 0.1);
    }
    .workspace-btn.occupied label {
        color: rgba(255, 255, 255, 0.7);
    }
    .workspace-btn.urgent {
        background-color: rgba(255, 85, 85, 0.3);
    }
    .workspace-btn.urgent label {
        color: #ff5555;
    }
    .stats-red { color: ${shared.colors.red}; }
    .stats-orange { color: ${shared.colors.orange}; }
    .stats-yellow { color: ${shared.colors.yellow}; }
    .stats-green { color: ${shared.colors.green}; }
    .stats-blue-green { color: ${shared.colors.blueGreen}; }
    .stats-cyan { color: ${shared.colors.cyan}; }
    .stats-blue { color: ${shared.colors.blue}; }
    .stats-magenta { color: ${shared.colors.magenta}; }
    .stats-white { color: ${shared.colors.white}; }
  '';

  ##########################################
  # SYSTEM STATS WIDGET JS MODULE
  ##########################################
  systemStatsJS = ''
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';

    // Inject the configured modules from Nix
    const modulesList = ${builtins.toJSON systemStatsModules};

    // ---------------------------------------------------------------
    // Safe executor for shell commands with error handling
    // ---------------------------------------------------------------
    function safeExec(command, errorMsg, defaultValue = 'N/A') {
        try {
            const output = exec(command);
            const result = output.trim();
            if (!result) throw new Error('Empty result');
            return result;
        } catch (error) {
            console.log(errorMsg, error);
            return defaultValue;
        }
    }

    // Cache for system stats to avoid unnecessary updates
    const statsCache = {
        lastUpdate: 0,
        data: {}
    };

    // ---------------------------------------------------------------
    // Retrieves various system stats (CPU, GPU, RAM, etc.)
    // ---------------------------------------------------------------
    function getStats() {
        // Only update stats every second to avoid excessive CPU usage
        const now = Date.now();
        if (now - statsCache.lastUpdate < 1000 && Object.keys(statsCache.data).length > 0) {
            return statsCache.data;
        }

        const cpuTempCmd = ["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"];
        const cpu_temp = safeExec(cpuTempCmd, "Failed to get CPU stats:");
        const gpuCmd = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
        let gpu_temp = safeExec(gpuCmd, "Failed to get GPU stats:");
        if (gpu_temp !== "N/A") {
            gpu_temp += "°C";
        }
        
        // More efficient RAM info parsing
        const ramInfo = safeExec(
            ["bash", "-c", "free -h | awk 'NR==2 {print $3\"|\"$2}'"], 
            "Failed to get RAM info:"
        ).split("|");
        const used_ram = ramInfo[0] || "N/A";
        const total_ram = ramInfo[1] || "N/A";
        
        const time = safeExec('date "+%H:%M:%S"', "Failed to get time:");
        const date = safeExec('date "+%d/%m/%y"', "Failed to get date:");
        const uptime = safeExec(
            ["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"],
            "Failed to get uptime:"
        ).trim();
        const pkgs = safeExec(
            ["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"],
            "Failed to get package count:"
        ).trim();
        const shell = safeExec(
            ["bash", "-c", "basename $(readlink -f $SHELL)"],
            "Failed to get shell:"
        );
        
        statsCache.lastUpdate = now;
        statsCache.data = {
            cpu_temp,
            gpu_temp,
            used_ram,
            total_ram,
            time,
            date,
            uptime,
            pkgs,
            shell
        };
        
        return statsCache.data;
    }

    // ---------------------------------------------------------------
    // Updates the widget's stats display with fresh data
    // ---------------------------------------------------------------
    function updateStats(stats) {
        const newStats = getStats();
        stats.cpu_temp.value = newStats.cpu_temp;
        stats.gpu_temp.value = newStats.gpu_temp;
        stats.used_ram.value = newStats.used_ram;
        stats.total_ram.value = newStats.total_ram;
        stats.time.value = newStats.time;
        stats.date.value = newStats.date;
        stats.uptime.value = newStats.uptime;
        stats.pkgs.value = newStats.pkgs;
        stats.shell.value = newStats.shell;
    }

    // ---------------------------------------------------------------
    // Constructs the main System Stats widget layout with configurable modules
    // ---------------------------------------------------------------
    function SystemStats() {
        var stats = {
            cpu_temp: Variable('N/A'),
            gpu_temp: Variable('N/A'),
            used_ram: Variable('N/A'),
            total_ram: Variable('N/A'),
            time: Variable('00:00:00'),
            date: Variable('00/00/00'),
            uptime: Variable('N/A'),
            pkgs: Variable('N/A'),
            shell: Variable('N/A')
        };

        const modules = modulesList;
        const longestLabel = Math.max(...modules.map(l => l.length));

        function padLabel(label) {
            return label + " ".repeat(longestLabel - label.length);
        }
        function horizontalBorder(l, filler, r) {
            return l + filler.repeat(longestLabel + 4) + r;
        }

        function createStatRow(module) {
            let value;
            switch(module) {
                case "time":
                    value = stats.time.bind();
                    break;
                case "date":
                    value = stats.date.bind();
                    break;
                case "shell":
                    value = stats.shell.bind();
                    break;
                case "uptime":
                    value = stats.uptime.bind();
                    break;
                case "pkgs":
                    value = stats.pkgs.bind();
                    break;
                case "memory":
                    value = stats.used_ram.bind().transform(
                        used => used + " | " + stats.total_ram.value
                    );
                    break;
                case "cpu":
                    value = stats.cpu_temp.bind();
                    break;
                case "gpu":
                    value = stats.gpu_temp.bind();
                    break;
                case "colors":
                    value = "";
                    break;
                default:
                    value = "";
            }
            const row = [
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: "│ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: "• " }),
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: padLabel(module) + " │ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: value })
            ];
            if (module === 'colors') {
                row.push(
                    Widget.Label({ class_name: 'stats-red', label: '• ' }),
                    Widget.Label({ class_name: 'stats-orange', label: '• ' }),
                    Widget.Label({ class_name: 'stats-yellow', label: '• ' }),
                    Widget.Label({ class_name: 'stats-green', label: '• ' }),
                    Widget.Label({ class_name: 'stats-blue-green', label: '• ' }),
                    Widget.Label({ class_name: 'stats-cyan', label: '• ' }),
                    Widget.Label({ class_name: 'stats-blue', label: '• ' }),
                    Widget.Label({ class_name: 'stats-magenta', label: '• ' }),
                    Widget.Label({ class_name: 'stats-white', label: '• ' })
                );
            }
            return Widget.Box({ children: row });
        }

        return Widget.Box({
            class_name: 'system-stats',
            vertical: true,
            children: [
                // AGS logo as text
                Widget.Label({
                    class_name: 'stats-white',
                    label: "   _  ___      ____  ____\n  / |/ (_)_ __/ __ \\/ __/\n /    / /\\ \\ / /_/ /\\ \\  \n/_/|_/_//_\\_\\\\____/___/  "
                }),
                // Top border line
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╭", "─", "╮")
                }),
                // Generate a row for each enabled module
                ...modules.map(createStatRow),
                // Bottom border line
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╰", "─", "╯")
                })
            ],
            setup: function(self) {
                self.poll(1000, () => updateStats(stats));
            }
        });
    }

    // Create a window for the System Stats widget and export its config
    var systemStatsWindow = Widget.Window({
        name: 'system-stats',
        child: SystemStats(),
        layer: 'bottom'
    });
    var systemStatsConfig = {
        window: systemStatsWindow,
        profile: {
            showStats: function() {
                systemStatsWindow.layer = 'top';
            },
            hideStats: function() {
                systemStatsWindow.layer = 'bottom';
            }
        }
    };

    export { systemStatsConfig };
  '';

  ##########################################
  # WORKSPACES WIDGET JS MODULE
  ##########################################
  workspacesJS = ''
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import Service from 'resource:///com/github/Aylur/ags/service.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';

    var hyprland = await Service.import('hyprland');
    
    // Cache for workspace state to avoid unnecessary updates
    const workspaceCache = {
        active: new Set(),
        occupied: new Set(),
        focused: null
    };

    function dispatch(workspace) {
        return hyprland.messageAsync("dispatch workspace " + workspace);
    }

    function createWorkspaceButton(index) {
        return Widget.Button({
            class_name: "workspace-btn",
            child: Widget.Label({ label: String(index) }),
            onClicked: () => dispatch(index),
            setup: self => {
                self.hook(hyprland, () => {
                    // Get workspace states
                    const occupiedWorkspaces = new Set(
                        hyprland.workspaces
                            .filter(ws => ws.windows > 0)
                            .map(ws => ws.id)
                    );
                    
                    const activeWorkspaces = new Set(
                        hyprland.monitors
                            .map(m => m.activeWorkspace && m.activeWorkspace.id)
                            .filter(id => id != null)
                    );
                    
                    const focusedMonitor = hyprland.focused_monitor || (hyprland.monitors[0] || {});
                    const focusedWorkspace = focusedMonitor.activeWorkspace && focusedMonitor.activeWorkspace.id;
                    
                    // Only update if state has changed
                    const isOccupied = occupiedWorkspaces.has(index);
                    const isActive = activeWorkspaces.has(index);
                    const isFocused = focusedWorkspace === index;
                    
                    // Check if state changed before updating
                    const occupiedChanged = workspaceCache.occupied.has(index) !== isOccupied;
                    const activeChanged = workspaceCache.active.has(index) !== isActive;
                    const focusedChanged = workspaceCache.focused !== focusedWorkspace;
                    
                    if (occupiedChanged || activeChanged || focusedChanged) {
                        // Update cache
                        if (isOccupied) workspaceCache.occupied.add(index);
                        else workspaceCache.occupied.delete(index);
                        
                        if (isActive) workspaceCache.active.add(index);
                        else workspaceCache.active.delete(index);
                        
                        workspaceCache.focused = focusedWorkspace;
                        
                        // Update UI
                        self.visible = isActive || isOccupied || isFocused;
                        self.toggleClassName('active', isFocused);
                        self.toggleClassName('occupied', isOccupied);
                        self.toggleClassName('urgent', false); // Add logic for urgent workspaces if needed
                    }
                });
            }
        });
    }

    function Workspaces() {
        var buttons = [];
        for (var i = 1; i <= 10; i++) {
            buttons.push(createWorkspaceButton(i));
        }
        return Widget.Box({
            class_name: "workspaces",
            children: buttons
        });
    }

    var workspacesWindowBottom = Widget.Window({
        name: "workspaces-bottom",
        anchor: ["bottom"],
        child: Workspaces(),
        layer: "overlay",
        margins: [0, 0, 0, 0]
    });
    var workspacesWindowTop = Widget.Window({
        name: "workspaces-top",
        anchor: ["top"],
        child: Workspaces(),
        layer: "overlay",
        margins: [0, 0, 0, 0]
    });

    var workspacesConfig = {
        windows: [workspacesWindowBottom, workspacesWindowTop],
        profile: {}
    };

    export { workspacesConfig };
  '';
in {
  # Include the AGS package for installation
  home.packages = with pkgs; [ags];

  # Create the AGS configuration directory and files
  xdg.configFile = {
    "ags/config.js".text = configJS;
    "ags/style.css".text = styleCSS;
    "ags/system-stats.js".text = systemStatsJS;
    "ags/workspaces.js".text = workspacesJS;
  };
}
