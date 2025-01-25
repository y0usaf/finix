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
          style: `''${App.configDir}/system-stats-style.css`,
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

    "ags/system-stats-style.css".text = ''
      /* Reset all inherited styles */
      .system-stats * {
          margin: 0 !important;
          padding: 0 !important;
          background: none !important;
          border: none !important;
          box-shadow: none !important;
          text-shadow: none !important;
          font-family: inherit !important;
          font-size: inherit !important;
          font-weight: inherit !important;
          color: inherit !important;
      }

      /* System Stats Styles */
      .system-stats {
          font-family: monospace !important;
          font-weight: bold !important;
          color: #FFFFFF !important;
          -webkit-text-stroke: 0.5em #000000 !important;
      }

      .system-stats label {
          margin: 4px !important;
          min-width: 100px !important;
      }

      .stats-time {
          font-size: 96px !important;
      }

      .stats-info {
          font-size: 24px !important;
      }
    '';

    "ags/workspaces-style.css".text = ''
      /* Reset all inherited styles */
      .workspaces * {
          margin: 0 !important;
          padding: 0 !important;
          background: none !important;
          border: none !important;
          box-shadow: none !important;
          text-shadow: none !important;
          font-family: inherit !important;
          font-size: inherit !important;
          font-weight: inherit !important;
          color: inherit !important;
      }

      /* Workspaces Styles */
      .workspaces {
          background: none !important;
          padding: 0 !important;
          spacing: 0 !important;
      }

      .workspace-btn {
          min-width: 16px !important;
          min-height: 16px !important;
          margin: 0 !important;
          font-family: monospace !important;
          font-weight: bold !important;
          background: none !important;
          border: none !important;
          box-shadow: none !important;
          padding: 0 !important;
          color: #333333 !important;
          -webkit-text-stroke: 0.5em #000000 !important;
      }

      .workspace-btn.active {
          color: #FFFFFF !important;
      }
    '';

    "ags/system-stats.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';

      const getStats = () => {
          // Get CPU temp with error handling
          let cpu_temp = 'N/A';
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
          let gpu_temp = 'N/A';
          try {
              gpu_temp = exec("nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits").trim();
              if (!gpu_temp) {
                  throw new Error('No GPU temperature reading available');
              }
          } catch (error) {
              console.log('Failed to get GPU stats:', error);
          }

          // Get RAM info
          const ram = exec('free -h').split('\n')[1].split(/\s+/);
          const used_ram = ram[2];
          const total_ram = ram[1];

          // Get time and date
          const time = exec('date "+%H:%M:%S"');
          const date = exec('date "+%d/%m/%y"');

          return {
              cpu_temp: cpu_temp !== 'N/A' ? cpu_temp : 'N/A',
              gpu_temp: gpu_temp !== 'N/A' ? gpu_temp + "°C" : 'N/A',
              used_ram,
              total_ram,
              time: time.trim(),
              date: date.trim(),
          };
      };

      const SystemStats = () => Widget.Box({
          class_name: 'system-stats',
          vertical: true,
          setup: self => {
              self.poll(1000, box => {
                  const stats = getStats();
                  box.children = [
                      Widget.Label({
                          class_name: 'stats-time',
                          label: stats.time
                      }),
                      Widget.Label({
                          class_name: 'stats-info',
                          label: stats.date
                      }),
                      Widget.Label({
                          class_name: 'stats-info',
                          label: 'CPU: ' + stats.cpu_temp
                      }),
                      Widget.Label({
                          class_name: 'stats-info',
                          label: 'GPU: ' + stats.gpu_temp
                      }),
                      Widget.Label({
                          class_name: 'stats-info',
                          label: 'RAM: ' + stats.used_ram + '/' + stats.total_ram
                      })
                  ];
              });
          }
      });

      // Create the window
      const systemStatsWindow = Widget.Window({
          name: 'system-stats',
          child: SystemStats(),
          layer: 'background',  // Start in background
      });

      export const systemStatsConfig = {
          window: systemStatsWindow,
          globals: {
              showStats: () => {
                  systemStatsWindow.layer = 'top';
              },
              hideStats: () => {
                  systemStatsWindow.layer = 'background';
              },
          },
      };
    '';

    "ags/workspaces.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import Service from 'resource:///com/github/Aylur/ags/service.js';

      const hyprland = await Service.import('hyprland');

      // Wait for hyprland service to be ready
      const dispatch = workspace => hyprland.messageAsync(`dispatch workspace ''${workspace}`);

      const Workspaces = () => {
          return Widget.Box({
              class_name: 'workspaces',
              children: Array.from({ length: 10 }, (_, i) => i + 1).map(i =>
                  Widget.Button({
                      class_name: 'workspace-btn',
                      attribute: i,
                      label: `''${i}`,
                      onClicked: () => dispatch(i),
                      setup: self => {
                          // Update active state when workspace changes
                          self.hook(hyprland, () => {
                              const activeId = hyprland.active.workspace.id;
                              const occupied = hyprland.workspaces.some(ws => ws.id === i);

                              // Only show if workspace is occupied
                              self.visible = occupied;

                              // Set active class if this is the current workspace
                              self.toggleClassName('active', activeId === i);
                          });
                      },
                  })
              ),
          });
      };

      // Create the window
      const workspacesWindow = Widget.Window({
          name: 'workspaces',
          anchor: ['bottom'],
          child: Workspaces(),
          layer: 'overlay',
          margins: [0, 0, 0, 0],
      });

      export const workspacesConfig = {
          window: workspacesWindow,
          globals: {},
      };
    '';
  };
}
