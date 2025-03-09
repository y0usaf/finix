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
    "ags/app.ts".text = ''
      import { App } from "astal/gtk3"
      import style from "./style.scss"
      import Bar from "./widget/Bar"

      App.start({
          css: style,
          main() {
              App.get_monitors().map(Bar)
          },
      })
    '';

    # SCSS styling
    "ags/style.scss".text = ''
      // https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/theme/Adwaita/_colors-public.scss
      $fg-color: #{"@theme_fg_color"};
      $bg-color: #{"@theme_bg_color"};

      window.Bar {
          background: transparent;
          color: $fg-color;
          font-weight: bold;

          >centerbox {
              background: $bg-color;
              border-radius: 10px;
              margin: 8px;
          }

          button {
              border-radius: 8px;
              margin: 2px;
          }
      }
    '';

    # TypeScript declarations
    "ags/env.d.ts".text = ''
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
    "ags/tsconfig.json".text = ''
      {
          "$schema": "https://json.schemastore.org/tsconfig",
          "compilerOptions": {
              "experimentalDecorators": true,
              "strict": true,
              "target": "ES2022",
              "module": "ES2022",
              "moduleResolution": "Bundler",
              // "checkJs": true,
              // "allowJs": true,
              "jsx": "react-jsx",
              "jsxImportSource": "astal/gtk3",
          }
      }
    '';

    # Package configuration
    "ags/package.json".text = ''
      {
          "name": "astal-shell",
          "dependencies": {
              "astal": "/nix/store/9c0pmm7xai3v3ghmr0mgywprrykqj64v-astal-gjs-0-unstable-2025-02-20/share/astal/gjs"
          }
      }
    '';

    # Gitignore
    "ags/.gitignore".text = ''
      node_modules/
      @girs/
    '';

    # Widget directory with Bar component
    "ags/widget/Bar.tsx".text = ''
      import { App, Astal, Gtk, Gdk } from "astal/gtk3"
      import { Variable } from "astal"

      const time = Variable("").poll(1000, "date")

      export default function Bar(gdkmonitor: Gdk.Monitor) {
          const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

          return <window
              className="Bar"
              gdkmonitor={gdkmonitor}
              exclusivity={Astal.Exclusivity.EXCLUSIVE}
              anchor={TOP | LEFT | RIGHT}
              application={App}>
              <centerbox>
                  <button
                      onClicked="echo hello"
                      halign={Gtk.Align.CENTER}
                  >
                      Welcome to AGS!
                  </button>
                  <box />
                  <button
                      onClicked={() => print("hello")}
                      halign={Gtk.Align.CENTER}
                  >
                      <label label={time()} />
                  </button>
              </centerbox>
          </window>
      }
    '';
  };
}
