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
      const config = {
          style: App.configDir + '/style.css',
          windows: [
              systemStatsConfig.window,
              workspacesConfig.window,
          ],
      };

      // Export global functions from modules
      Object.assign(globalThis, {
          ...systemStatsConfig.globals,
          ...workspacesConfig.globals,
      });

      export default config;
    '';

    "ags/style.css".text = ''
      /* System Stats Styles */
      .system-stats {
          font-family: monospace;
          font-weight: bold;
          color: #FFFFFF;
          text-shadow: -1px -1px 0px #000000,
                      1px -1px 0px #000000,
                      -1px 1px 0px #000000,
                      1px 1px 0px #000000,
                      -1px 0px 0px #000000,
                      1px 0px 0px #000000,
                      0px -1px 0px #000000,
                      0px 1px 0px #000000;
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

      /* Workspaces Styles */
      .workspaces {
          background: none;
          padding: 0;
      }

      .workspace-btn {
          min-width: 16px;
          min-height: 24px;
          margin: 0 1px;
          font-family: monospace;
          font-weight: bold;
          background: none;
          border: none;
          box-shadow: none;
          padding: 0;
          color: #333333;
          text-shadow: -1px -1px 0px #000000,
                      1px -1px 0px #000000,
                      -1px 1px 0px #000000,
                      1px 1px 0px #000000,
                      -1px 0px 0px #000000,
                      1px 0px 0px #000000,
                      0px -1px 0px #000000,
                      0px 1px 0px #000000;
      }

      .workspace-btn.active {
          color: #FF0000;
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
