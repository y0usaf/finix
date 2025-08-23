{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.ags.bar-overlay;
in {
  options.home.ui.ags.bar-overlay = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 Bar Overlay (Minimal time/date bars)";
    };
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [
        pkgs.ags
      ];
      files = {
        ".config/ags-bar-overlay/app.tsx" = {
          clobber = true;
          text = ''
            import { App, Astal, Gtk } from "astal/gtk3"
            import { Variable, exec } from "astal"

            // ============================================================================
            // QUICKSHELL-STYLE MINIMALIST STYLING
            // ============================================================================
            const styles = `
            * {
                font-size: 14px;
                font-family: monospace;
            }

            .bar-top, .bar-bottom {
                background: transparent;
            }

            .bar {
                background: transparent;
                margin: 0;
                padding: 0;
            }

            .time-block, .date-block {
                background: #2a2a2a;
                border-radius: 0;
                padding: 2px;
                margin: 0;
                color: white;
            }

            .time-block label, .date-block label {
                background: transparent;
                color: white;
                margin: 0;
                padding: 0;
                text-shadow:
                    1px 0 1px black,
                    -1px 0 1px black,
                    0 1px 1px black,
                    0 -1px 1px black;
            }
            `

            // ============================================================================
            // TIME AND DATE VARIABLES
            // ============================================================================
            const time = Variable("").poll(1000, () => exec(["date", "+%H:%M:%S"]))
            const date = Variable("").poll(30000, () => exec(["date", "+%d/%m/%y"]))

            // ============================================================================
            // BAR COMPONENTS
            // ============================================================================
            function TopBar() {
                return <window
                    className="bar-top"
                    layer={Astal.Layer.OVERLAY}
                    exclusivity={Astal.Exclusivity.IGNORE}
                    anchor={Astal.WindowAnchor.TOP}
                    application={App}>
                    <box className="bar" spacing={8}>
                        <box className="time-block">
                            <label label={time()} />
                        </box>
                        <box className="date-block">
                            <label label={date()} />
                        </box>
                    </box>
                </window>
            }

            function BottomBar() {
                return <window
                    className="bar-bottom"
                    layer={Astal.Layer.OVERLAY}
                    exclusivity={Astal.Exclusivity.IGNORE}
                    anchor={Astal.WindowAnchor.BOTTOM}
                    application={App}>
                    <box className="bar" spacing={8}>
                        <box className="time-block">
                            <label label={time()} />
                        </box>
                        <box className="date-block">
                            <label label={date()} />
                        </box>
                    </box>
                </window>
            }

            // ============================================================================
            // APP
            // ============================================================================
            App.start({
                css: styles,
                main() {
                    TopBar()
                    BottomBar()
                },
            })
          '';
        };
        ".config/ags-bar-overlay/tsconfig.json" = {
          clobber = true;
          text = ''
            {
              "compilerOptions": {
                "target": "ES2022",
                "module": "ES2022",
                "lib": ["ES2022"],
                "allowJs": true,
                "strict": true,
                "esModuleInterop": true,
                "skipLibCheck": true,
                "forceConsistentCasingInFileNames": true,
                "moduleResolution": "node",
                "jsx": "react-jsx",
                "jsxImportSource": "astal/gtk3/jsx-runtime"
              },
              "include": ["**/*.ts", "**/*.tsx"],
              "exclude": ["node_modules"]
            }
          '';
        };
      };
    };
  };
}
