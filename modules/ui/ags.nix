{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  configJS = ''
    // This file consolidates the previous app.js, system-stats.js, and workspaces.js
    // into one file and uses a new configuration layout.

    import Widget from 'resource:///com/github/Aylur/ags/widget.js';
    import { exec } from 'resource:///com/github/Aylur/ags/utils.js';
    import Variable from 'resource:///com/github/Aylur/ags/variable.js';
    import Service from 'resource:///com/github/Aylur/ags/service.js';
    import App from 'resource:///com/github/Aylur/ags/app.js';

    // New flattened configuration:
    // - workspaces is enabled if workspaces.enable is true
    // - systemStats is enabled if systemStats.enable is true and the systemStatsModules list is nonempty
    const config = {
      workspaces: {
        enable: true
      },
      systemStats: {
        enable: true,
        systemStatsModules: [] // Change to a nonempty array (e.g. ["time", "date", ...]) to show stats rows.
      }
    };

    // A simple profile with a base font size
    const profile = {
      baseFontSize: 16
    };

    // ----- Style and Resets --------------------------------
    // Shadow settings used for generating text shadows
    const shared = {
      shadowSize: "0.05rem",
      shadowRadius: "0.05rem",
      shadowColor: "#000000",
      repetitionCount: 4
    };
    const shadowOffsets = [
      "$${shared.shadowSize} 0",
      "-$${shared.shadowSize} 0",
      "0 $${shared.shadowSize}",
      "0 -$${shared.shadowSize}",
      "$${shared.shadowSize} $${shared.shadowSize}",
      "-$${shared.shadowSize} $${shared.shadowSize}",
      "$${shared.shadowSize} -$${shared.shadowSize}",
      "-$${shared.shadowSize} -$${shared.shadowSize}"
    ];
    const repeatedShadow = Array.from({ length: shared.repetitionCount })
      .flatMap(() => shadowOffsets.map(offset => "$${offset} $${shared.shadowRadius} $${shared.shadowColor}"))
      .join(", ");

    const baseReset = "margin: 0; padding: 0; background: none; border: none; box-shadow: none;";
    const systemStatsReset = "$${baseReset} text-shadow: $${repeatedShadow}; font-family: inherit; font-size: inherit; font-weight: inherit; color: inherit;";
    const workspacesReset = "$${baseReset} color: white;";

    const styleCSS = ""
      html { font-size: $${profile.baseFontSize}px; }

      /* Global resets */
      .system-stats *, .workspaces * { $${systemStatsReset} }
      .workspaces, .workspaces * { $${workspacesReset} }

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
    "";

    // ----- System Stats Widget --------------------------------
    // Helper to safely execute a command and return its (trimmed) output.
    function safeExec(command, errorMsg, defaultValue = 'N/A') {
      try {
        const output = exec(command);
        return output.trim() || defaultValue;
      } catch (error) {
        console.log(errorMsg, error);
        return defaultValue;
      }
    }

    // Retrieve several stats by executing commands.
    function getStats() {
      return {
        cpu_temp: safeExec(
          ["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"],
          "CPU stats error:"
        ),
        gpu_temp: safeExec(
          "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits",
          "GPU stats error:"
        ) + "°C",
        used_ram: exec("free -h").split("\n")[1].split(/\\s+/)[2],
        total_ram: exec("free -h").split("\n")[1].split(/\\s+/)[1],
        time: safeExec('date "+%H:%M:%S"', "Time error:"),
        date: safeExec('date "+%d/%m/%y"', "Date error:"),
        uptime: safeExec(
          ["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"],
          "Uptime error:"
        ).trim(),
        pkgs: safeExec(
          ["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"],
          "Package count error:"
        ).trim(),
        shell: safeExec(
          ["bash", "-c", "basename $(readlink -f $SHELL)"],
          "Shell error:"
        )
      };
    }

    // The SystemStats widget creates a box with rows (one per module) and polls for changes.
    function SystemStats() {
      // Set up state holders using Variable from AGS.
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

      // Pick up the list from the configuration.
      const modulesList = config.systemStats.systemStatsModules;
      const longestLabel = modulesList.length ? Math.max(...modulesList.map(l => l.length)) : 0;
      const padLabel = label => label + " ".repeat(longestLabel - label.length);
      const horizontalBorder = (l, filler, r) => l + filler.repeat(longestLabel + 4) + r;

      function createStatRow(module) {
        let value;
        switch (module) {
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
            value = stats.used_ram.bind().transform(used => used + " | " + stats.total_ram.value);
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
          const colors = ['red', 'orange', 'yellow', 'green', 'blue-green', 'cyan', 'blue', 'magenta', 'white'];
          row.push(...colors.map(color => Widget.Label({ class_name: 'stats-' + color, label: '• ' })));
        }

        return Widget.Box({ children: row });
      }

      // Build the rows (if any).
      const statRows = modulesList.map(createStatRow);

      const box = Widget.Box({
        class_name: 'system-stats',
        vertical: true,
        children: [
          // Draw a simple logo (the NixOS logo in ASCII art)
          Widget.Label({
            class_name: 'stats-white',
            label: "   _  ___      ____  ____\n  / |/ (_)_ __/ __ \\/ __/\n /    / /\\ \\ / /_/ /\\ \\  \n/_/|_/_//_\\_\\\\____/___/  "
          }),
          Widget.Label({
            class_name: 'stats-white',
            xalign: 0,
            label: horizontalBorder("╭", "─", "╮")
          }),
          ...statRows,
          Widget.Label({
            class_name: 'stats-white',
            xalign: 0,
            label: horizontalBorder("╰", "─", "╯")
          })
        ],
        setup: self => {
          // Poll for updates every 1000ms.
          self.poll(1000, () => {
            const newStats = getStats();
            Object.entries(newStats).forEach(([key, value]) => {
              stats[key].value = value;
            });
          });
        }
      });

      return box;
    }

    // ----- Workspaces Widget --------------------------------
    // First import the hyprland service (assuming top-level await is allowed).
    const hyprland = await Service.import('hyprland');

    function createWorkspaceButton(index) {
      return Widget.Button({
        class_name: "workspace-btn",
        child: Widget.Label({ label: String(index) }),
        onClicked: () => hyprland.messageAsync("dispatch workspace " + index),
        setup: self => {
          self.hook(hyprland, () => {
            const isOccupied = hyprland.workspaces.some(ws => ws.windows > 0 && ws.id === index);
            const activeIds = hyprland.monitors.map(m => m.activeWorkspace?.id).filter(Boolean);
            const isActive = activeIds.includes(index);
            const focusedMonitor = hyprland.focused_monitor || (hyprland.monitors[0] || {});
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
        children: Array.from({ length: 10 }, (_, i) => createWorkspaceButton(i + 1))
      });
    }

    // ----- Assemble Windows and Apply the Configuration ---
    // We build an array of windows based on the new configuration.
    const windows = [];
    let systemStatsWindow = null;

    if (config.systemStats.enable) {
      // Even if the systemStatsModules list is empty this widget is created.
      // (it will show only the header/logo and borders)
      systemStatsWindow = Widget.Window({
        name: 'system-stats',
        child: SystemStats(),
        layer: 'bottom'
      });
      windows.push(systemStatsWindow);
    }

    if (config.workspaces.enable) {
      const workspacesWidget = Workspaces();
      const workspacesWindows = [
        Widget.Window({
          name: "workspaces-bottom",
          anchor: ["bottom"],
          child: workspacesWidget,
          layer: "overlay",
          margins: [0, 0, 0, 0]
        }),
        Widget.Window({
          name: "workspaces-top",
          anchor: ["top"],
          child: workspacesWidget,
          layer: "overlay",
          margins: [0, 0, 0, 0]
        })
      ];
      windows.push(...workspacesWindows);
    }

    // Expose any profiles globally.
    // For example, we provide methods for showing/hiding the system stats widget.
    const systemStatsProfile = systemStatsWindow ? {
      showStats: () => systemStatsWindow.layer = 'top',
      hideStats: () => systemStatsWindow.layer = 'bottom'
    } : {};

    Object.assign(globalThis, {
      ...systemStatsProfile,
      // Additional profiles (such as workspaces) can be added here.
    });

    // Finalize the configuration for AGS.
    App.config({
      style: styleCSS,  // now using the generated CSS string from this file
      windows: windows
    });
  '';
in {
  # Include the AGS package
  home.packages = with pkgs; [ags];

  # Create configuration files
  xdg.configFile = {
    "ags/app.js".text = configJS;
  };
}
