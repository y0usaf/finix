{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Simplified shadow configuration
  shared = {
    shadowSize = "0.05rem";
    shadowRadius = "0.05rem";
    shadowColor = "#000000";
    repetitionCount = 4;
  };

  # System stats modules configuration
  systemStatsModules = ["time" "date" "shell" "uptime" "pkgs" "memory" "cpu" "gpu" "colors"];

  # Generate shadow effect more efficiently
  shadowOffsets = [
    "${shared.shadowSize} 0"
    "-${shared.shadowSize} 0"
    "0 ${shared.shadowSize}"
    "0 -${shared.shadowSize}"
    "${shared.shadowSize} ${shared.shadowSize}"
    "-${shared.shadowSize} ${shared.shadowSize}"
    "${shared.shadowSize} -${shared.shadowSize}"
    "-${shared.shadowSize} -${shared.shadowSize}"
  ];

  repeatedShadow = lib.concatStringsSep ", " (lib.flatten (
    lib.genList (
      i:
        map (offset: "${offset} ${shared.shadowRadius} ${shared.shadowColor}") shadowOffsets
    )
    shared.repetitionCount
  ));

  # Simplified CSS resets
  baseReset = "margin: 0; padding: 0; background: none; border: none; box-shadow: none;";
  systemStatsReset = "${baseReset} text-shadow: ${repeatedShadow}; font-family: inherit; font-size: inherit; font-weight: inherit; color: inherit;";
  workspacesReset = "${baseReset} color: white;";

  # Main configuration file for AGS v2
  configJS = ''
    // AGS v2 main configuration file
    import App from 'resource:///com/github/Aylur/ags/app.js';
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';
    import Service from 'resource:///com/github/Aylur/ags/service.js';

    const { exec, interval } = Utils;

    // ===== SYSTEM STATS MODULE =====

    // Configured modules from Nix
    const modulesList = ${builtins.toJSON systemStatsModules};

    // Safe executor for shell commands
    function safeExec(command, errorMsg, defaultValue = 'N/A') {
        try {
            const output = exec(command);
            return output.trim() || defaultValue;
        } catch (error) {
            console.log(errorMsg, error);
            return defaultValue;
        }
    }

    // Get system stats
    function getStats() {
        return {
            cpu_temp: safeExec(["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"], "CPU stats error:"),
            gpu_temp: safeExec("nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits", "GPU stats error:") + "°C",
            used_ram: exec("free -h").split("\\n")[1].split(/\\s+/)[2],
            total_ram: exec("free -h").split("\\n")[1].split(/\\s+/)[1],
            time: safeExec('date "+%H:%M:%S"', "Time error:"),
            date: safeExec('date "+%d/%m/%y"', "Date error:"),
            uptime: safeExec(["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"], "Uptime error:").trim(),
            pkgs: safeExec(["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"], "Package count error:").trim(),
            shell: safeExec(["bash", "-c", "basename $(readlink -f $SHELL)"], "Shell error:")
        };
    }

    // Create system stats widget
    function SystemStats() {
        const stats = {
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

        const longestLabel = Math.max(...modulesList.map(l => l.length));
        const padLabel = label => label + " ".repeat(longestLabel - label.length);
        const horizontalBorder = (l, filler, r) => l + filler.repeat(longestLabel + 4) + r;

        function createStatRow(module) {
            let value;
            switch(module) {
                case "time": value = stats.time.bind(); break;
                case "date": value = stats.date.bind(); break;
                case "shell": value = stats.shell.bind(); break;
                case "uptime": value = stats.uptime.bind(); break;
                case "pkgs": value = stats.pkgs.bind(); break;
                case "memory": value = stats.used_ram.bind().transform(used => used + " | " + stats.total_ram.value); break;
                case "cpu": value = stats.cpu_temp.bind(); break;
                case "gpu": value = stats.gpu_temp.bind(); break;
                case "colors": value = ""; break;
                default: value = "";
            }

            const row = [
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: "│ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: "• " }),
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: padLabel(module) + " │ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: value })
            ];

            if (module === 'colors') {
                const colors = ['red', 'orange', 'yellow', 'green', 'blue-green', 'cyan', 'blue', 'magenta', 'white'];
                row.push(...colors.map(color => Widget.Label({ class_name: 'stats-' + color, label: '• ' })));
            }

            return Widget.Box({ children: row });
        }

        return Widget.Box({
            class_name: 'system-stats',
            vertical: true,
            children: [
                // NixOS logo
                Widget.Label({
                    class_name: 'stats-white',
                    label: "   _  ___      ____  ____\n  / |/ (_)_ __/ __ \\/ __/\n /    / /\\ \\ / /_/ /\\ \\  \n/_/|_/_//_\\_\\\\____/___/  "
                }),
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╭", "─", "╮")
                }),
                ...modulesList.map(createStatRow),
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╰", "─", "╯")
                })
            ],
            setup: self => {
                self.poll(1000, () => {
                    const newStats = getStats();
                    Object.entries(newStats).forEach(([key, value]) => {
                        stats[key].value = value;
                    });
                });
            }
        });
    }

    // Create system stats window
    const systemStatsWindow = Widget.Window({
        name: 'system-stats',
        child: SystemStats(),
        layer: 'bottom'
    });

    const systemStatsConfig = {
        window: systemStatsWindow,
        profile: {
            showStats: () => systemStatsWindow.layer = 'top',
            hideStats: () => systemStatsWindow.layer = 'bottom'
        }
    };

    // ===== WORKSPACES MODULE =====

    // Initialize hyprland service
    const hyprland = await Service.import('hyprland');

    function createWorkspaceButton(index) {
        return Widget.Button({
            class_name: "workspace-btn",
            child: Widget.Label({ label: String(index) }),
            onClicked: () => hyprland.messageAsync("dispatch workspace " + index),
            setup: self => {
                self.hook(hyprland, () => {
                    const isOccupied = hyprland.workspaces.some(ws => ws.windows > 0 && ws.id === index);
                    const activeIds = hyprland.monitors
                        .map(m => m.activeWorkspace?.id)
                        .filter(Boolean);
                    const isActive = activeIds.includes(index);
                    const focusedMonitor = hyprland.focused_monitor || hyprland.monitors[0] || {};
                    const isFocused = focusedMonitor.activeWorkspace?.id === index;

                    self.visible = isActive || isOccupied || isFocused;
                    self.toggleClassName('active', isFocused);
                    self.toggleClassName('occupied', isOccupied);
                });
            }
        });
    }

    function Workspaces() {
        return Widget.Box({
            class_name: "workspaces",
            children: Array.from({length: 10}, (_, i) => createWorkspaceButton(i + 1))
        });
    }

    const workspacesWindows = [
        Widget.Window({
            name: "workspaces-bottom",
            anchor: ["bottom"],
            child: Workspaces(),
            layer: "overlay",
            margins: [0, 0, 0, 0]
        }),
        Widget.Window({
            name: "workspaces-top",
            anchor: ["top"],
            child: Workspaces(),
            layer: "overlay",
            margins: [0, 0, 0, 0]
        })
    ];

    const workspacesConfig = {
        windows: workspacesWindows,
        profile: {}
    };

    // ===== MAIN APP CONFIG =====

    App.config({
        style: `
            html { font-size: ${toString profile.baseFontSize}px; }

            /* Global resets */
            .system-stats *, .workspaces * { ${systemStatsReset} }
            .workspaces, .workspaces * { ${workspacesReset} }

            /* System Stats Styles */
            .system-stats {
                text-shadow: 1pt 1pt 1pt rgba(0,0,0,0.5);
                font-size: 1rem;
                margin: 0.5em;
            }

            /* Color classes */
            .stats-time { color: #ff0000; }
            .stats-date { color: #ff8800; }
            .stats-shell { color: #ffff00; }
            .stats-uptime { color: #00ff00; }
            .stats-pkgs { color: #00ff88; }
            .stats-memory { color: #00ffff; }
            .stats-cpu { color: #0088ff; }
            .stats-gpu { color: #ff00ff; }
            .stats-colors { color: #ffffff; }
            .stats-red { color: #ff0000; }
            .stats-orange { color: #ff8800; }
            .stats-yellow { color: #ffff00; }
            .stats-green { color: #00ff00; }
            .stats-blue-green { color: #00ff88; }
            .stats-cyan { color: #00ffff; }
            .stats-blue { color: #0088ff; }
            .stats-magenta { color: #ff00ff; }
            .stats-white { color: #ffffff; }

            /* Workspaces Widget Styles */
            .workspace-btn {
                background-color: #222;
                border-radius: 0;
            }
            .workspace-btn label {
                background: none;
                color: rgba(255, 255, 255, 0.4);
                font-size: 0.8rem;
                padding: 0.25em;
            }
            .workspace-btn.active label { color: rgba(255, 255, 255, 1.0); }
            .workspace-btn.inactive label { color: rgba(255, 255, 255, 0.5); }
            .workspace-btn.urgent label { color: #ff5555; }
        `,
        windows: [
            systemStatsConfig.window,
            ...workspacesConfig.windows,
        ],
    });

    // Export functions to global scope
    Object.assign(globalThis, {
        ...systemStatsConfig.profile,
        ...workspacesConfig.profile,
    });
  '';

  # Create a config.js file that uses the v1 API
  configV1JS = ''
    // AGS v1 main configuration file
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';
    import Service from 'resource:///com/github/Aylur/ags/service.js';
    const { exec, interval } = Utils;
    const { Application } = imports.gi.Gio;
    const App = Application.get_default();

    // ===== SYSTEM STATS MODULE =====

    // Configured modules from Nix
    const modulesList = ${builtins.toJSON systemStatsModules};

    // Safe executor for shell commands
    function safeExec(command, errorMsg, defaultValue = 'N/A') {
        try {
            const output = exec(command);
            return output.trim() || defaultValue;
        } catch (error) {
            console.log(errorMsg, error);
            return defaultValue;
        }
    }

    // Get system stats
    function getStats() {
        return {
            cpu_temp: safeExec(["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"], "CPU stats error:"),
            gpu_temp: safeExec("nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits", "GPU stats error:") + "°C",
            used_ram: exec("free -h").split("\\n")[1].split(/\\s+/)[2],
            total_ram: exec("free -h").split("\\n")[1].split(/\\s+/)[1],
            time: safeExec('date "+%H:%M:%S"', "Time error:"),
            date: safeExec('date "+%d/%m/%y"', "Date error:"),
            uptime: safeExec(["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"], "Uptime error:").trim(),
            pkgs: safeExec(["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"], "Package count error:").trim(),
            shell: safeExec(["bash", "-c", "basename $(readlink -f $SHELL)"], "Shell error:")
        };
    }

    // Create system stats widget
    function SystemStats() {
        const stats = {
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

        const longestLabel = Math.max(...modulesList.map(l => l.length));
        const padLabel = label => label + " ".repeat(longestLabel - label.length);
        const horizontalBorder = (l, filler, r) => l + filler.repeat(longestLabel + 4) + r;

        function createStatRow(module) {
            let value;
            switch(module) {
                case "time": value = stats.time.bind(); break;
                case "date": value = stats.date.bind(); break;
                case "shell": value = stats.shell.bind(); break;
                case "uptime": value = stats.uptime.bind(); break;
                case "pkgs": value = stats.pkgs.bind(); break;
                case "memory": value = stats.used_ram.bind().transform(used => used + " | " + stats.total_ram.value); break;
                case "cpu": value = stats.cpu_temp.bind(); break;
                case "gpu": value = stats.gpu_temp.bind(); break;
                case "colors": value = ""; break;
                default: value = "";
            }

            const row = [
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: "│ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: "• " }),
                Widget.Label({ class_name: 'stats-white', xalign: 0, label: padLabel(module) + " │ " }),
                Widget.Label({ class_name: "stats-" + module, xalign: 0, label: value })
            ];

            if (module === 'colors') {
                const colors = ['red', 'orange', 'yellow', 'green', 'blue-green', 'cyan', 'blue', 'magenta', 'white'];
                row.push(...colors.map(color => Widget.Label({ class_name: 'stats-' + color, label: '• ' })));
            }

            return Widget.Box({ children: row });
        }

        return Widget.Box({
            class_name: 'system-stats',
            vertical: true,
            children: [
                // NixOS logo
                Widget.Label({
                    class_name: 'stats-white',
                    label: "   _  ___      ____  ____\n  / |/ (_)_ __/ __ \\/ __/\n /    / /\\ \\ / /_/ /\\ \\  \n/_/|_/_//_\\_\\\\____/___/  "
                }),
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╭", "─", "╮")
                }),
                ...modulesList.map(createStatRow),
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╰", "─", "╯")
                })
            ],
            setup: self => {
                self.poll(1000, () => {
                    const newStats = getStats();
                    Object.entries(newStats).forEach(([key, value]) => {
                        stats[key].value = value;
                    });
                });
            }
        });
    }

    // Create system stats window
    const systemStatsWindow = Widget.Window({
        name: 'system-stats',
        child: SystemStats(),
        layer: 'bottom'
    });

    const systemStatsConfig = {
        window: systemStatsWindow,
        profile: {
            showStats: () => systemStatsWindow.layer = 'top',
            hideStats: () => systemStatsWindow.layer = 'bottom'
        }
    };

    // ===== WORKSPACES MODULE =====

    // Initialize hyprland service
    const hyprland = await Service.import('hyprland');

    function createWorkspaceButton(index) {
        return Widget.Button({
            class_name: "workspace-btn",
            child: Widget.Label({ label: String(index) }),
            onClicked: () => hyprland.messageAsync("dispatch workspace " + index),
            setup: self => {
                self.hook(hyprland, () => {
                    const isOccupied = hyprland.workspaces.some(ws => ws.windows > 0 && ws.id === index);
                    const activeIds = hyprland.monitors
                        .map(m => m.activeWorkspace?.id)
                        .filter(Boolean);
                    const isActive = activeIds.includes(index);
                    const focusedMonitor = hyprland.focused_monitor || hyprland.monitors[0] || {};
                    const isFocused = focusedMonitor.activeWorkspace?.id === index;

                    self.visible = isActive || isOccupied || isFocused;
                    self.toggleClassName('active', isFocused);
                    self.toggleClassName('occupied', isOccupied);
                });
            }
        });
    }

    function Workspaces() {
        return Widget.Box({
            class_name: "workspaces",
            children: Array.from({length: 10}, (_, i) => createWorkspaceButton(i + 1))
        });
    }

    const workspacesWindows = [
        Widget.Window({
            name: "workspaces-bottom",
            anchor: ["bottom"],
            child: Workspaces(),
            layer: "overlay",
            margins: [0, 0, 0, 0]
        }),
        Widget.Window({
            name: "workspaces-top",
            anchor: ["top"],
            child: Workspaces(),
            layer: "overlay",
            margins: [0, 0, 0, 0]
        })
    ];

    const workspacesConfig = {
        windows: workspacesWindows,
        profile: {}
    };

    // ===== MAIN APP CONFIG =====

    App.config({
        style: `
            html { font-size: ${toString profile.baseFontSize}px; }

            /* Global resets */
            .system-stats *, .workspaces * { ${systemStatsReset} }
            .workspaces, .workspaces * { ${workspacesReset} }

            /* System Stats Styles */
            .system-stats {
                text-shadow: 1pt 1pt 1pt rgba(0,0,0,0.5);
                font-size: 1rem;
                margin: 0.5em;
            }

            /* Color classes */
            .stats-time { color: #ff0000; }
            .stats-date { color: #ff8800; }
            .stats-shell { color: #ffff00; }
            .stats-uptime { color: #00ff00; }
            .stats-pkgs { color: #00ff88; }
            .stats-memory { color: #00ffff; }
            .stats-cpu { color: #0088ff; }
            .stats-gpu { color: #ff00ff; }
            .stats-colors { color: #ffffff; }
            .stats-red { color: #ff0000; }
            .stats-orange { color: #ff8800; }
            .stats-yellow { color: #ffff00; }
            .stats-green { color: #00ff00; }
            .stats-blue-green { color: #00ff88; }
            .stats-cyan { color: #00ffff; }
            .stats-blue { color: #0088ff; }
            .stats-magenta { color: #ff00ff; }
            .stats-white { color: #ffffff; }

            /* Workspaces Widget Styles */
            .workspace-btn {
                background-color: #222;
                border-radius: 0;
            }
            .workspace-btn label {
                background: none;
                color: rgba(255, 255, 255, 0.4);
                font-size: 0.8rem;
                padding: 0.25em;
            }
            .workspace-btn.active label { color: rgba(255, 255, 255, 1.0); }
            .workspace-btn.inactive label { color: rgba(255, 255, 255, 0.5); }
            .workspace-btn.urgent label { color: #ff5555; }
        `,
        windows: [
            systemStatsConfig.window,
            ...workspacesConfig.windows,
        ],
    });

    // Export functions to global scope
    Object.assign(globalThis, {
        ...systemStatsConfig.profile,
        ...workspacesConfig.profile,
    });
  '';
in {
  # Include the AGS package
  home.packages = with pkgs; [
    ags
  ];

  # Create configuration files
  xdg.configFile = {
    "ags/config.js".text = configV1JS;
  };
}
