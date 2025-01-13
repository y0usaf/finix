{
  config,
  pkgs,
  lib,
  inputs,
  globals,
  ...
}: {
  home.packages = with pkgs; [
    inputs.ags.packages.${pkgs.system}.default
    inputs.astal.packages.${pkgs.system}.default
    inputs.astal.packages.${pkgs.system}.astal3
    inputs.astal.packages.${pkgs.system}.io
    gobject-introspection
  ];

  # Main app configuration
  xdg.configFile."astal/app.ts" = {
    text = ''
      import { App } from '@astal/widgets';
      import config from './config';

      export default config;
    '';
  };

  # Main configuration file
  xdg.configFile."astal/config.ts" = {
    text = ''
      import { App, Widget } from '@astal/widgets';
      import { Variable } from '@astal/utils';

      // State management
      const volume = new Variable(0);
      const brightness = new Variable(0);

      // Create the app
      const app = new App({
        name: 'y0usaf-config',
        windows: [
          {
            name: 'bar',
            anchor: ['top', 'left', 'right'],
            exclusive: true,
            child: Widget.Box({
              className: 'bar',
              children: [
                // Left section
                Widget.Box({
                  className: 'left',
                  children: [
                    Widget.Workspaces(),
                  ],
                }),

                // Center section
                Widget.Box({
                  className: 'center',
                  children: [
                    Widget.Clock({
                      format: '%H:%M',
                    }),
                  ],
                }),

                // Right section
                Widget.Box({
                  className: 'right',
                  children: [
                    Widget.Volume({
                      value: volume,
                    }),
                    Widget.Battery(),
                    Widget.Network(),
                  ],
                }),
              ],
            }),
          },
        ],
      });

      export default app;
    '';
  };

  # Styling
  xdg.configFile."astal/style.css" = {
    text = ''
      .bar {
        background-color: rgba(0, 0, 0, 0.8);
        color: white;
        padding: 8px;
      }

      .left, .center, .right {
        padding: 0 8px;
      }

      .workspaces button {
        padding: 0 4px;
        margin: 0 2px;
        border-radius: 4px;
      }

      .workspaces button:hover {
        background-color: rgba(255, 255, 255, 0.1);
      }

      .workspaces button.active {
        background-color: rgba(255, 255, 255, 0.2);
      }
    '';
  };

  # Add Astal to Hyprland autostart
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "astal"
    ];
    layerrule = [
      "blur, astal"
    ];
  };

  # Ensure config directory exists
  home.activation.astalSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/astal
  '';
}
