{
  config,
  pkgs,
  lib,
  globals,
  ...
}:
lib.mkIf globals.enableAgs {
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
          ...systemStatsConfig.globals,
          ...workspacesConfig.globals,
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
          color: #FFFFFF;
          text-shadow:
            /* 1st repetition */
            2px 0 2px #000000,
            -2px 0 2px #000000,
            0 2px 2px #000000,
            0 -2px 2px #000000,
            2px 2px 2px #000000,
            -2px 2px 2px #000000,
            2px -2px 2px #000000,
            -2px -2px 2px #000000,

            /* 2nd repetition */
            2px 0 2px #000000,
            -2px 0 2px #000000,
            0 2px 2px #000000,
            0 -2px 2px #000000,
            2px 2px 2px #000000,
            -2px 2px 2px #000000,
            2px -2px 2px #000000,
            -2px -2px 2px #000000,

            /* 3rd repetition */
            2px 0 2px #000000,
            -2px 0 2px #000000,
            0 2px 2px #000000,
            0 -2px 2px #000000,
            2px 2px 2px #000000,
            -2px 2px 2px #000000,
            2px -2px 2px #000000,
            -2px -2px 2px #000000,

            /* 4th repetition */
            2px 0 2px #000000,
            -2px 0 2px #000000,
            0 2px 2px #000000,
            0 -2px 2px #000000,
            2px 2px 2px #000000,
            -2px 2px 2px #000000,
            2px -2px 2px #000000,
            -2px -2px 2px #000000;
      }

      .system-stats label {
          margin: 4px;
          min-width: 100px;
          text-shadow: inherit;
      }

      .stats-time {
          font-size: 96px;
      }

      .stats-info {
          font-size: 24px;
      }

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
          const cpuTempCmd = ['bash', '-c', "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"];
          const cpu_temp = safeExec(cpuTempCmd, 'Failed to get CPU stats:');

          // Get GPU temperature
          const gpuCmd = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
          let gpu_temp = safeExec(gpuCmd, 'Failed to get GPU stats:');
          if (gpu_temp !== 'N/A') {
              gpu_temp += "°C";
          }

          // Get RAM info
          const ramInfo = exec('free -h').split('\n')[1].split(/\s+/);
          const used_ram = ramInfo[2];
          const total_ram = ramInfo[1];

          // Get date and time
          const time = safeExec('date "+%H:%M:%S"', 'Failed to get time:');
          const date = safeExec('date "+%d/%m/%y"', 'Failed to get date:');

          return {
               cpu_temp,
               gpu_temp,
               used_ram,
               total_ram,
               time,
               date
          };
      }

      function SystemStats() {
          // Create variables to hold state
          var stats = {
              cpu_temp: Variable('N/A'),
              gpu_temp: Variable('N/A'),
              used_ram: Variable('N/A'),
              total_ram: Variable('N/A'),
              time: Variable('00:00:00'),
              date: Variable('00/00/00')
          };

          // Update function
          function updateStats() {
              var newStats = getStats();
              Object.keys(newStats).forEach(function(key) {
                  stats[key].value = newStats[key];
              });
          }

          return Widget.Box({
              class_name: 'system-stats',
              vertical: true,
              children: [
                  Widget.Label({
                      class_name: 'stats-time',
                      label: stats.time.bind()
                  }),
                  Widget.Label({
                      class_name: 'stats-info',
                      label: stats.date.bind()
                  }),
                  Widget.Label({
                      class_name: 'stats-info',
                      label: stats.cpu_temp.bind().transform(function(temp) {
                          return "CPU: " + temp;
                      })
                  }),
                  Widget.Label({
                      class_name: 'stats-info',
                      label: stats.gpu_temp.bind().transform(function(temp) {
                          return "GPU: " + temp;
                      })
                  }),
                  Widget.Label({
                      class_name: 'stats-info',
                      label: stats.used_ram.bind().transform(function(used) {
                          return "RAM: " + used + "/" + stats.total_ram.value;
                      })
                  })
              ],
              setup: function(self) {
                  self.poll(1000, updateStats);
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
          globals: {
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
          globals: {}
      };

      export { workspacesConfig };
    '';
  };
}
