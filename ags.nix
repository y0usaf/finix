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
              workspacesConfig.window,
          ],
      });

      // Export global functions from modules
      Object.assign(globalThis, {
          ...systemStatsConfig.globals,
          ...workspacesConfig.globals,
      });
    '';

    "ags/style.css".text = ''
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
          -webkit-text-stroke: 0.5em #000000;
      }

      .system-stats label {
          margin: 4px;
          min-width: 100px;
      }

      .stats-time {
          font-size: 96px;
      }

      .stats-info {
          font-size: 24px;
      }

      /* Test Workspaces Styles */
      .workspace-btn {
          min-width: 20px;
          min-height: 20px;
          margin: 0 4px;
          padding: 4px;
          border-radius: 4px;
          background-color: rgba(255, 255, 255, 0.1);
          color: rgba(255, 255, 255, 0.5);  /* Dimmed color for inactive */
      }

      .workspace-btn label {
          font-size: 16px;
          font-weight: bold;
          color: inherit;  /* Use inherited color */
      }

      .workspace-btn.active {
          background-color: rgba(255, 255, 255, 0.3);  /* Brighter background */
          box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.4);
          color: rgba(255, 255, 255, 1);  /* Full white for active */
      }

      .workspace-btn.active label {
          color: #ffffff;
          font-weight: bold;
      }
    '';

    "ags/system-stats.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';
      import Variable from 'resource:///com/github/Aylur/ags/variable.js';

      function getStats() {
          // Get CPU temp with error handling
          var cpu_temp = 'N/A';
          try {
              cpu_temp = exec(['bash', '-c', "sensors k10temp-pci-00c3 | awk '/Tctl/ {print substr($2,2)}'"]).trim();
              if (!cpu_temp) {
                  throw new Error('No CPU temperature reading available');
              }
          } catch (error) {
              console.log('Failed to get CPU stats:', error);
              console.log('Error details:', error.message);
          }

          // Get GPU temp using nvidia-smi
          var gpu_temp = 'N/A';
          try {
              gpu_temp = exec("nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits").trim();
              if (!gpu_temp) {
                  throw new Error('No GPU temperature reading available');
              }
          } catch (error) {
              console.log('Failed to get GPU stats:', error);
          }

          // Get RAM info
          var ram = exec('free -h').split('\n')[1].split(/\s+/);
          var used_ram = ram[2];
          var total_ram = ram[1];

          // Get time and date
          var time = exec('date "+%H:%M:%S"');
          var date = exec('date "+%d/%m/%y"');

          return {
              cpu_temp: cpu_temp !== 'N/A' ? cpu_temp : 'N/A',
              gpu_temp: gpu_temp !== 'N/A' ? gpu_temp + "°C" : 'N/A',
              used_ram: used_ram,
              total_ram: total_ram,
              time: time.trim(),
              date: date.trim()
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
                      // Get all active workspace IDs from the monitors
                      const activeIds = hyprland.monitors
                          .filter(m => m.active_workspace)
                          .map(m => m.active_workspace.id);
                      const isActive = activeIds.includes(index);

                      // Check if the workspace is occupied (has any windows)
                      const isOccupied = hyprland.workspaces
                          .filter(ws => ws.windows > 0)
                          .map(ws => ws.id)
                          .includes(index);

                      // Also include the currently focused workspace if it's not already active/occupied.
                      const focusedWorkspace = hyprland["focused-workspace"];
                      const isFocused = focusedWorkspace && focusedWorkspace.id === index;

                      // Logging for debugging purposes (note the escaped $ signs)
                      console.log(`Workspace $${index} - active: $${isActive}, occupied: $${isOccupied}, focused: $${!!isFocused}`);
                      console.log(`Active IDs: $${JSON.stringify(activeIds)}`);
                      console.log(`Focused workspace: $${JSON.stringify(focusedWorkspace)}`);
                      console.log(`Hyprland workspaces: $${JSON.stringify(hyprland.workspaces)}`);

                      // Only show workspaces that are active, focused, or have windows
                      self.visible = isActive || isOccupied || isFocused;
                      // Mark the workspace as active if it is active or focused.
                      self.toggleClassName('active', isActive || isFocused);
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

      var workspacesWindow = Widget.Window({
          name: "workspaces",
          anchor: ["bottom"],
          child: Workspaces(),
          layer: "overlay",
          margins: [0, 0, 0, 0]
      });

      var workspacesConfig = {
          window: workspacesWindow,
          globals: {}
      };

      export { workspacesConfig };
    '';
  };
}
