{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  # Include the AGS package
  home.packages = with pkgs; [ags];

  # Create configuration files
  xdg.configFile = {
    # Main TypeScript files
    "ags/app.ts".source = pkgs.writeText "app.ts" ''
      import { App } from "astal/gtk3"
      import style from "./style.scss"
      import TimeWidget from "./widget/TimeWidget"

      App.start({
          css: style,
          main() {
              App.get_monitors().map(TimeWidget)
          },
      })
    '';

    # SCSS styling
    "ags/style.scss".source = pkgs.writeText "style.scss" ''
      // https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/theme/Adwaita/_colors-public.scss
      $fg-color: #{"@theme_fg_color"};
      $bg-color: #{"@theme_bg_color"};

      window.TimeWidget {
          background: transparent;
          color: $fg-color;
          font-weight: bold;

          >box {
              background: $bg-color;
              border-radius: 10px;
              padding: 16px 24px;
          }

          label {
              font-size: 24px;
          }
      }
    '';

    # TypeScript declarations
    "ags/env.d.ts".source = pkgs.writeText "env.d.ts" ''
      declare const SRC: string

      declare module "inline:*" {
          const content: string
          export default content
      }

      declare module "*.scss" {
          const content: string
          export default content
      }

      declare module "*.blp" {
          const content: string
          export default content
      }

      declare module "*.css" {
          const content: string
          export default content
      }
    '';

    # TypeScript configuration
    "ags/tsconfig.json".source = pkgs.writeText "tsconfig.json" ''
      {
          "$schema": "https://json.schemastore.org/tsconfig",
          "compilerOptions": {
              "experimentalDecorators": true,
              "strict": true,
              "target": "ES2022",
              "module": "ES2022",
              "moduleResolution": "node",
              // "checkJs": true,
              // "allowJs": true,
              "jsx": "react-jsx",
              "jsxImportSource": "astal/gtk3",
              "outDir": ".",
              "rootDir": "."
          }
      }
    '';

    # Package configuration
    "ags/package.json".source = pkgs.writeText "package.json" ''
      {
          "name": "astal-shell",
          "type": "module",
          "dependencies": {
              "astal": "/nix/store/9c0pmm7xai3v3ghmr0mgywprrykqj64v-astal-gjs-0-unstable-2025-02-20/share/astal/gjs"
          }
      }
    '';

    # Gitignore
    "ags/.gitignore".source = pkgs.writeText "gitignore" ''
      node_modules/
      @girs/
    '';

    # Widget directory with TimeWidget component
    "ags/widget/TimeWidget.tsx".source = pkgs.writeText "TimeWidget.tsx" ''
      import { App, Astal, Gtk, Gdk } from "astal/gtk3"
      import { Variable } from "astal"

      const time = Variable("").poll(1000, "date '+%H:%M:%S'")

      export default function TimeWidget(gdkmonitor: Gdk.Monitor) {
          const { CENTER } = Astal.WindowAnchor

          return <window
              className="TimeWidget"
              gdkmonitor={gdkmonitor}
              exclusivity={Astal.Exclusivity.EXCLUSIVE}
              anchor={CENTER}
              application={App}>
              <box>
                  <label label={time()} />
              </box>
          </window>
      }
    '';
  };
}
