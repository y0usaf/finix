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
  xdg.configFile."astal/config.js" = {
    text = ''
      import { App, Widget } from 'resource:///com/github/Aylur/astal/widgets.js';

      const win = Widget.Window({
        name: 'test',
        anchor: ['top'],
        child: Widget.Label({
          label: 'Hello, Astal!',
        }),
      });

      export default {
        windows: [win],
        style: './style.css',
      };
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
