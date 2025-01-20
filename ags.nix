{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  # Install AGS
  home.packages = with pkgs; [
    ags
  ];

  # Create AGS config directory and files
  xdg.configFile = {
    "ags/config.js".text = ''
      import SystemStats from './widgets/system-stats.js';
      import App from 'resource:///com/github/Aylur/ags/app.js';
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';

      // Create the window
      const systemStatsWindow = Widget.Window({
          name: 'system-stats',
          child: SystemStats(),
          layer: 'background',  // Start in background
      });

      // Configure the app
      const config = {
          style: App.configDir + '/style.css',
          windows: [systemStatsWindow],
      };

      // Add functions to global scope
      globalThis.showStats = () => {
          systemStatsWindow.layer = 'top';
      };

      globalThis.hideStats = () => {
          systemStatsWindow.layer = 'background';
      };

      // Export the config
      export default config;
    '';

    "ags/style.css".text = ''
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
          padding: 16px;
          margin-left: auto;
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
    '';

    "ags/widgets/system-stats.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';

      const getStats = () => {
          // Get CPU temp with error handling
          let cpu_temp = 'N/A';
          try {
              // Using bash -c to execute the piped command as a single string
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

      export default () => Widget.Box({
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
    '';
  };
}
