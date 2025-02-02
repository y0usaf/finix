{
  config,
  pkgs,
  lib,
  profile,
  ...
}:
lib.mkIf profile.enableAgs {
  # Install AGS and related packages
  home.packages = with pkgs; [
    ags
  ];

  # Create AGS config directory and files
  xdg.configFile = {
    "ags/config.js".text = ''
      import App from 'resource:///com/github/Aylur/ags/app.js';
      import { systemStatsConfig } from './system-stats.js';
      import { workspacesConfig } from './workspaces.js';

      // Configure the app using App.config()
      App.config({
          style: `''${App.configDir}/style.css`,
          windows: [
              systemStatsConfig.window,
              ...workspacesConfig.windows,
          ],
      });

      // Export global functions from modules
      Object.assign(globalThis, {
          ...systemStatsConfig.profile,
          ...workspacesConfig.profile,
      });
    '';

    "ags/style.css".text = ''
      /* Removed :root definitions and replaced usage of CSS variables with explicit values */

      /* Global reset for widgets */
      .system-stats *, .workspaces * {
          margin: 0;
          padding: 0;
          background: none;
          border: none;
          box-shadow: none;
          text-shadow: none;
          font-family: inherit;
          font-size: inherit;
          font-weight: inherit;
          color: inherit;
      }

      /* System Stats Styles */
      .system-stats {
          font-family: monospace;
          font-weight: bold;
          text-shadow: 2px 2px 2px rgba(0,0,0,0.5);
      }

      .system-stats label {
          margin: 4px;
          min-width: 100px;
          text-shadow: inherit;
      }

      .stats-header {
          font-size: 14px;
          margin-bottom: 8px;
          color: #00ffff; /* Cyan for the header */
      }

      .stats-time {
          font-size: 32px;
          margin-bottom: 4px;
          color: #ffffff;
      }

      .stats-date {
          font-size: 16px;
          margin-bottom: 8px;
          color: #ffffff;
      }

      .stats-shell { color: #ff00ff; }  /* Magenta */
      .stats-uptime { color: #0088ff; } /* Blue */
      .stats-pkgs { color: #ff0000; }   /* Red */
      .stats-memory { color: #ffff00; }  /* Yellow */
      .stats-cpu { color: #00ff00; }     /* Green */
      .stats-gpu { color: #00ffff; }     /* Cyan */
      .stats-colors { color: #ffffff; }   /* White */

      /* Box characters in white */
      .stats-box { color: #ffffff; }

      /* Reset and base styling for all widgets in the workspaces container */
      .workspaces *,
      .workspaces {
          margin: 0;
          padding: 0;
          background: none;
          border: none;
          box-shadow: none;
          font-size: 14px;
          /* Default color for widgets */
          color: white;
      }

      /* Workspace container styling */
      .workspaces {
          margin: 1px;
          background: none;
      }

      /* Workspace button styling */
      .workspace-btn {
          min-width: 14px;          /* small box width */
          min-height: 14px;         /* small box height */
          margin: 1px;              /* minimal gap */
          padding: 0 1px;           /* as minimal as possible */
          background-color: #222;   /* replaced var(--bg-color) */
          border-radius: 0;         /* sharp corners */
      }

      /* Workspace label (the number inside) */
      .workspace-btn label {
          background: none;
          /* Inactive / unfocused: lower opacity white */
          color: rgba(255, 255, 255, 0.4);  /* replaced var(--inactive-color) */
          font-size: 14px;
      }

      /* When a workspace is active (focused) */
      .workspace-btn.active label {
          color: rgba(255, 255, 255, 1.0);  /* replaced var(--active-color) */
      }

      /* When a workspace is marked as inactive */
      .workspace-btn.inactive label {
          color: rgba(255, 255, 255, 0.5);
      }

      /* When a workspace is urgent */
      .workspace-btn.urgent label {
          color: #ff5555;  /* replaced var(--urgent-color) */
      }

      /* White text for labels and borders */
      .stats-white { color: #ffffff; }
    '';

    "ags/system-stats.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';
      import Variable from 'resource:///com/github/Aylur/ags/variable.js';

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

      function getStats() {
          // Get CPU temperature
          const cpuTempCmd = ["bash", "-c", "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"];
          const cpu_temp = safeExec(cpuTempCmd, "Failed to get CPU stats:");

          // Get GPU temperature
          const gpuCmd = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
          let gpu_temp = safeExec(gpuCmd, "Failed to get GPU stats:");
          if (gpu_temp !== "N/A") {
              gpu_temp += "°C";
          }

          // Get RAM info
          const ramInfo = exec("free -h").split("\n")[1].split(/\s+/);
          const used_ram = ramInfo[2];
          const total_ram = ramInfo[1];

          // Get date and time
          const time = safeExec('date "+%H:%M:%S"', "Failed to get time:");
          const date = safeExec('date "+%d/%m/%y"', "Failed to get date:");

          // Fix uptime command - using awk to format the output
          const uptime = safeExec(
              ["bash", "-c", "uptime | awk -F'up |,' '{print $2}'"],
              "Failed to get uptime:"
          ).trim();

          // Fix package count
          const pkgs = safeExec(
              ["bash", "-c", "nix-store -q --requisites /run/current-system/sw | wc -l"],
              "Failed to get package count:"
          ).trim();

          // Get shell name without full path - using readlink to resolve the actual shell
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

          return Widget.Box({
              class_name: 'system-stats',
              vertical: true,
              children: [
                  Widget.Label({
                      class_name: 'stats-header',
                      label: "   _  ___      ____  ____\n  / |/ (_)_ __/ __ \\/ __/\n /    / /\\ \\ / /_/ /\\ \\  \n/_/|_/_//_\\_\\\\____/___/  "
                  }),
                  Widget.Label({
                      class_name: 'stats-time',
                      label: stats.time.bind()
                  }),
                  Widget.Label({
                      class_name: 'stats-date',
                      label: stats.date.bind()
                  }),
                  Widget.Label({
                      class_name: 'stats-white',
                      xalign: 0,
                      label: "╭───────────╮"
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-shell',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    shell  │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-shell',
                              xalign: 0,
                              label: stats.shell.bind()
                          })
                      ]
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-uptime',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    uptime │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-uptime',
                              xalign: 0,
                              label: stats.uptime.bind()
                          })
                      ]
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-pkgs',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    pkgs   │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-pkgs',
                              xalign: 0,
                              label: stats.pkgs.bind()
                          })
                      ]
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-memory',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    memory │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-memory',
                              xalign: 0,
                              label: stats.used_ram.bind().transform(used =>
                                  used + " | " + stats.total_ram.value)
                          })
                      ]
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-cpu',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    cpu    │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-cpu',
                              xalign: 0,
                              label: stats.cpu_temp.bind()
                          })
                      ]
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-gpu',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    gpu    │ "
                          }),
                          Widget.Label({
                              class_name: 'stats-gpu',
                              xalign: 0,
                              label: stats.gpu_temp.bind()
                          })
                      ]
                  }),
                  Widget.Label({
                      class_name: 'stats-white',
                      xalign: 0,
                      label: "├───────────┤"
                  }),
                  Widget.Box({
                      children: [
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "│ "
                          }),
                          Widget.Label({
                              class_name: 'stats-colors',
                              xalign: 0,
                              label: "•"
                          }),
                          Widget.Label({
                              class_name: 'stats-white',
                              xalign: 0,
                              label: "    colors │        "
                          })
                      ]
                  }),
                  Widget.Label({
                      class_name: 'stats-white',
                      xalign: 0,
                      label: "╰───────────╯"
                  })
              ],
              setup: function(self) {
                  self.poll(1000, () => updateStats(stats));
              }
          });
      }

      var systemStatsWindow = Widget.Window({
          name: 'system-stats',
          child: SystemStats(),
          layer: 'background'
      });

      var systemStatsConfig = {
          window: systemStatsWindow,
          profile: {
              showStats: function() {
                  systemStatsWindow.layer = 'top';
              },
              hideStats: function() {
                  systemStatsWindow.layer = 'background';
              }
          }
      };

      export { systemStatsConfig };
    '';

    "ags/workspaces.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import Service from 'resource:///com/github/Aylur/ags/service.js';
      import Variable from 'resource:///com/github/Aylur/ags/variable.js';

      var hyprland = await Service.import('hyprland');

      function dispatch(workspace) {
          return hyprland.messageAsync("dispatch workspace " + workspace);
      }

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

                      // Get focused monitor or fallback to the first monitor
                      const focusedMonitor = hyprland.focused_monitor || (hyprland.monitors[0] || {});
                      const isFocused = focusedMonitor.activeWorkspace && focusedMonitor.activeWorkspace.id === index;

                      self.visible = isActive || isOccupied || isFocused;
                      self.toggleClassName('active', isFocused);
                      self.toggleClassName('occupied', isOccupied);
                  });
              }
          });
      }

      function Workspaces() {
          // Create buttons for all possible workspaces but only show active ones
          var buttons = [];
          for (var i = 1; i <= 10; i++) {
              buttons.push(createWorkspaceButton(i));
          }

          return Widget.Box({
              class_name: "workspaces",
              children: buttons
          });
      }

      // Create two workspace windows: one anchored at the bottom, one at the top.
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

      // Export both windows as an array in the config.
      var workspacesConfig = {
          windows: [workspacesWindowBottom, workspacesWindowTop],
          profile: {}
      };

      export { workspacesConfig };
    '';
  };
}
