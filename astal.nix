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

      const app = new App({
        name: 'y0usaf-config',
        windows: [
          {
            name: 'test',
            anchor: ['top'],
            child: Widget.Label({
              label: 'Hello, Astal!',
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
      window {
        background-color: rgba(0, 0, 0, 0.8);
        color: white;
      }
    '';
  };

  # Ensure config directory exists
  home.activation.astalSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/astal
  '';
}
