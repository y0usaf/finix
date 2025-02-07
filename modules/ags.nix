{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  ###########################################################################
  ##                     AGS SHARED VALUES (for DRY CSS)                   ##
  ###########################################################################
  # Define common values so that you can easily adjust them in one place.
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "#000000";

  # Define the 8 shadow offsets as a list (one repetition)
  shadowOffsets = [
    "${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "-${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "0 ${shadowSize} ${shadowRadius} ${shadowColor}"
    "0 -${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
  ];

  # How many times do we want to repeat these values?
  repetitionCount = 4;
  # Use lib.genList to generate a list with the shadowOffsets repeated
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (i: shadowOffsets) repetitionCount));

  ###########################################################################
  ##                     AGS MAIN APP CONFIGURATION JS                     ##
  ###########################################################################
  configJS = ''
    // Import the core App and the module configurations
    import App from 'resource:///com/github/Aylur/ags/app.js';
    import { systemStatsConfig } from './system-stats.js';
    import { workspacesConfig } from './workspaces.js';

    // Configure the main AGS application with style and windows
    App.config({
        style: `''${App.configDir}/style.css`,
        windows: [
            systemStatsConfig.window,
            ...workspacesConfig.windows,
        ],
    });

    // Merge exported module functions into the global namespace
    Object.assign(globalThis, {
        ...systemStatsConfig.profile,
        ...workspacesConfig.profile,
    });
  '';

  ###########################################################################
  ##                            AGS STYLE CSS                              ##
  ###########################################################################
  styleCSS = ''
    /* --------------------------------------------------------------------- */
    /*        Base Font Size Setting via profile.baseFontSize                 */
    /* --------------------------------------------------------------------- */
    html {
      font-size: ${toString profile.baseFontSize}px;
    }

    /* --------------------------------------------------------------------- */
    /*              Global CSS Reset for Widgets (system-stats & workspaces)  */
    /* --------------------------------------------------------------------- */
    .system-stats *, .workspaces * {
        margin: 0;
        padding: 0;
        background: none;
        border: none;
        box-shadow: none;
        /* Instead of typing all offsets manually, we interpolate the shadow string */
        text-shadow: ${repeatedShadow};
        font-family: inherit;
        font-size: inherit;
        font-weight: inherit;
        color: inherit;
    }

    /* --------------------------------------------------------------------- */
    /*                        System Stats Specific Styles                   */
    /* --------------------------------------------------------------------- */
    .system-stats {
        text-shadow: 1pt 1pt 1pt rgba(0,0,0,0.5);
        font-size: 1rem;  /* Relative to the base font size */
        margin: 0.5em;
    }
    .system-stats label {
        margin: 0;
        padding: 0;
    }

    /* --------------------------------------------------------------------- */
    /*            Color Assignments for Stats (rainbow order)                */
    /* --------------------------------------------------------------------- */
    .stats-time { color: #ff0000; }     /* Red */
    .stats-date { color: #ff8800; }     /* Orange */
    .stats-shell { color: #ffff00; }    /* Yellow */
    .stats-uptime { color: #00ff00; }   /* Green */
    .stats-pkgs { color: #00ff88; }     /* Blue-Green */
    .stats-memory { color: #00ffff; }   /* Cyan */
    .stats-cpu { color: #0088ff; }      /* Blue */
    .stats-gpu { color: #ff00ff; }      /* Magenta */
    .stats-colors { color: #ffffff; }   /* White */

    /* --------------------------------------------------------------------- */
    /*                      Workspaces Widget Styling                        */
    /* --------------------------------------------------------------------- */
    .workspaces *,
    .workspaces {
        margin: 0;
        padding: 0;
        background: none;
        border: none;
        box-shadow: none;
        color: white;
    }
    .workspaces {
        margin: 0;
        background: none;
    }
    .workspace-btn {
        margin: 0;
        padding: 0;
        background-color: #222;
        border-radius: 0;
    }
    .workspace-btn label {
        background: none;
        color: rgba(255, 255, 255, 0.4);
        font-size: 0.5rem;
        padding: 0.1rem 0.2rem;
    }
    .workspace-btn.active label {
        color: rgba(255, 255, 255, 1.0);
    }
    .workspace-btn.inactive label {
        color: rgba(255, 255, 255, 0.5);
    }
    .workspace-btn.urgent label {
        color: #ff5555;
    }

    /* --------------------------------------------------------------------- */
    /*                       Additional Color Dot Styling                    */
    /* --------------------------------------------------------------------- */
    .stats-red { color: #ff0000; }
    .stats-orange { color: #ff8800; }
    .stats-yellow { color: #ffff00; }
    .stats-green { color: #00ff00; }
    .stats-blue-green { color: #00ff88; }
    .stats-cyan { color: #00ffff; }
    .stats-blue { color: #0088ff; }
    .stats-magenta { color: #ff00ff; }
    .stats-white { color: #ffffff; }
  '';

  ###########################################################################
  ##                     SYSTEM STATS WIDGET JS                            ##
  ###########################################################################
  systemStatsJS = ''
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';

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

    // ---------------------------------------------------------------
    // Retrieves various system stats (CPU, GPU, RAM, etc.)
    // ---------------------------------------------------------------
    function getStats() {
        // CPU Temperature
        const cpuTempCmd = ["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"];
        const cpu_temp = safeExec(cpuTempCmd, "Failed to get CPU stats:");

        // GPU Temperature
        const gpuCmd = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
        let gpu_temp = safeExec(gpuCmd, "Failed to get GPU stats:");
        if (gpu_temp !== "N/A") {
            gpu_temp += "°C";
        }

        // RAM usage details using 'free'
        const ramInfo = exec("free -h").split("\n")[1].split(/\s+/);
        const used_ram = ramInfo[2];
        const total_ram = ramInfo[1];

        // Date and Time
        const time = safeExec('date "+%H:%M:%S"', "Failed to get time:");
        const date = safeExec('date "+%d/%m/%y"', "Failed to get date:");

        // Uptime and package count information
        const uptime = safeExec(
            ["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"],
            "Failed to get uptime:"
        ).trim();
        const pkgs = safeExec(
            ["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"],
            "Failed to get package count:"
        ).trim();

        // Shell name without full path
        const shell = safeExec(
            ["bash", "-c", "basename $(readlink -f $SHELL)"],
            "Failed to get shell:"
        );

        return {
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
    // Constructs the main System Stats widget layout
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

        // Define row labels and compute the longest one for padding
        const labels = ['time', 'date', 'shell', 'uptime', 'pkgs', 'memory', 'cpu', 'gpu', 'colors'];
        const longestLabel = Math.max(...labels.map(l => l.length));

        // Pad the label string for alignment
        function padLabel(label) {
            return label + ' '.repeat(longestLabel - label.length);
        }

        // Generate a horizontal border
        function horizontalBorder(char1, char2, char3) {
            return char1 + "─".repeat(longestLabel + 4) + char3;
        }

        return Widget.Box({
            class_name: 'system-stats',
            vertical: true,
            children: [
                // Display the AGS logo as text
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
                // Create a row for each stat label
                ...labels.map((currentLabel) => Widget.Box({
                    children: [
                        Widget.Label({
                            class_name: 'stats-white',
                            xalign: 0,
                            label: "│ "
                        }),
                        Widget.Label({
                            class_name: "stats-" + currentLabel,
                            xalign: 0,
                            label: "• "
                        }),
                        Widget.Label({
                            class_name: 'stats-white',
                            xalign: 0,
                            label: padLabel(currentLabel) + " │ "
                        }),
                        Widget.Label({
                            class_name: "stats-" + currentLabel,
                            xalign: 0,
                            label: (() => {
                                switch(currentLabel) {
                                    case 'time': return stats.time.bind();
                                    case 'date': return stats.date.bind();
                                    case 'shell': return stats.shell.bind();
                                    case 'uptime': return stats.uptime.bind();
                                    case 'pkgs': return stats.pkgs.bind();
                                    case 'memory': return stats.used_ram.bind().transform(used =>
                                        used + " | " + stats.total_ram.value);
                                    case 'cpu': return stats.cpu_temp.bind();
                                    case 'gpu': return stats.gpu_temp.bind();
                                    case 'colors': return "";
                                    default: return "";
                                }
                            })()
                        }),
                        // Append color dots for the "colors" row only
                        ...(currentLabel === 'colors' ? [
                            Widget.Label({ class_name: 'stats-red', label: '• ' }),
                            Widget.Label({ class_name: 'stats-orange', label: '• ' }),
                            Widget.Label({ class_name: 'stats-yellow', label: '• ' }),
                            Widget.Label({ class_name: 'stats-green', label: '• ' }),
                            Widget.Label({ class_name: 'stats-blue-green', label: '• ' }),
                            Widget.Label({ class_name: 'stats-cyan', label: '• ' }),
                            Widget.Label({ class_name: 'stats-blue', label: '• ' }),
                            Widget.Label({ class_name: 'stats-magenta', label: '• ' }),
                            Widget.Label({ class_name: 'stats-white', label: '• ' })
                        ] : [])
                    ]
                })),
                // Bottom border line
                Widget.Label({
                    class_name: 'stats-white',
                    xalign: 0,
                    label: horizontalBorder("╰", "─", "╯")
                })
            ],
            // Set up polling to update stats every second
            setup: function(self) {
                self.poll(1000, () => updateStats(stats));
            }
        });
    }

    // ---------------------------------------------------------------
    // Create a window for the System Stats widget and export its config
    // ---------------------------------------------------------------
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

  ###########################################################################
  ##                         WORKSPACES WIDGET JS                          ##
  ###########################################################################
  workspacesJS = ''
    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import Service from 'resource:///com/github/Aylur/ags/service.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';

    // ---------------------------------------------------------------
    // Asynchronously import the hyprland service
    // ---------------------------------------------------------------
    var hyprland = await Service.import('hyprland');

    // ---------------------------------------------------------------
    // Dispatches a workspace switch command
    // ---------------------------------------------------------------
    function dispatch(workspace) {
        return hyprland.messageAsync("dispatch workspace " + workspace);
    }

    // ---------------------------------------------------------------
    // Creates a button for an individual workspace
    // ---------------------------------------------------------------
    function createWorkspaceButton(index) {
        return Widget.Button({
            class_name: "workspace-btn",
            child: Widget.Label({
                label: String(index),
            }),
            onClicked: () => dispatch(index),
            setup: self => {
                self.hook(hyprland, () => {
                    const isOccupied = hyprland.workspaces.some(ws => ws.windows > 0 && ws.id === index);
                    const activeIds = hyprland.monitors
                        .map(m => m.activeWorkspace && m.activeWorkspace.id)
                        .filter(id => id != null);
                    const isActive = activeIds.includes(index);

                    // Check if the workspace is focused on the current monitor
                    const focusedMonitor = hyprland.focused_monitor || (hyprland.monitors[0] || {});
                    const isFocused = focusedMonitor.activeWorkspace && focusedMonitor.activeWorkspace.id === index;

                    self.visible = isActive || isOccupied || isFocused;
                    self.toggleClassName('active', isFocused);
                    self.toggleClassName('occupied', isOccupied);
                });
            }
        });
    }

    // ---------------------------------------------------------------
    // Constructs the workspaces container using workspace buttons
    // ---------------------------------------------------------------
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

    // ---------------------------------------------------------------
    // Define two workspace windows (bottom and top) for the layout
    // ---------------------------------------------------------------
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

    // ---------------------------------------------------------------
    // Export the workspaces configuration with both windows
    // ---------------------------------------------------------------
    var workspacesConfig = {
        windows: [workspacesWindowBottom, workspacesWindowTop],
        profile: {}
    };

    export { workspacesConfig };
  '';
in
  ###########################################################################
  ##                       AGS INSTALLATION CONFIG                         ##
  ###########################################################################
  lib.mkIf (builtins.elem "ags" profile.features) {
    # Include the AGS package for installation
    home.packages = with pkgs; [
      ags
    ];

    # Create the AGS configuration directory and files
    xdg.configFile = {
      "ags/config.js".text = configJS;
      "ags/style.css".text = styleCSS;
      "ags/system-stats.js".text = systemStatsJS;
      "ags/workspaces.js".text = workspacesJS;
    };
  }
