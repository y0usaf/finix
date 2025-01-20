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
          anchor: ['center', 'center'],
          child: SystemStats(),
          layer: 'background',  // Start in background
      });

      // Configure the app
      App.config({
          style: App.configDir + '/style.css',
          windows: [systemStatsWindow],
      });

      // Add functions to global scope
      globalThis.showStats = () => {
          systemStatsWindow.layer = 'top';
      };

      globalThis.hideStats = () => {
          systemStatsWindow.layer = 'background';
      };
    '';

    "ags/widgets/system-stats.js".text = ''
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import { exec, interval } from 'resource:///com/github/Aylur/ags/utils.js';

      const getStats = () => {
          const cpu_temp = exec("sensors | grep 'Tctl' | awk '{print $2}'");
          const ram = exec('free -h').split('\n')[1].split(/\s+/);
          const used_ram = ram[2];
          const total_ram = ram[1];
          const time = exec('date "+%H:%M:%S"');
          const date = exec('date "+%d/%m/%y"');

          return {
              cpu_temp: cpu_temp.trim(),
              used_ram,
              total_ram,
              time: time.trim(),
              date: date.trim(),
          };
      };

      export default () => Widget.Box({
          class_name: 'system-stats',
          vertical: true,
          css: `
              .system-stats {
                  font-family: monospace;
                  font-size: 24px;
                  font-weight: bold;
                  color: #FFFFFF;
                  text-shadow: 2px 2px 2px rgba(0, 0, 0, 0.5);
                  padding: 10px;
              }
          `,
          setup: self => {
              self.poll(1000, box => {
                  const stats = getStats();
                  box.children = [
                      Widget.Label({
                          label: `🕒 ''${stats.time} 📅 ''${stats.date}`
                      }),
                      Widget.Label({
                          label: `🌡️ CPU: ''${stats.cpu_temp}`
                      }),
                      Widget.Label({
                          label: `💾 RAM: ''${stats.used_ram}/''${stats.total_ram}`
                      })
                  ];
              });
          }
      });
    '';
  };
}
