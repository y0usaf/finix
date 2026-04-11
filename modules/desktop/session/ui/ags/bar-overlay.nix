{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.ui.ags.bar-overlay = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 Bar Overlay (Minimal time/date bars)";
    };
    modules = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "time"
        "date"
        "tray"
        "battery"
      ]);
      default = [
        "time"
        "date"
        "tray"
        "battery"
      ];
      description = "Bar overlay modules to enable";
    };
    exclusivity = lib.mkOption {
      type = lib.types.enum [
        "normal"
        "exclusive"
        "ignore"
      ];
      default = "ignore";
      description = ''
        Layer-shell exclusivity mode for the overlay windows.

        - `ignore`: float above windows without reserving screen space
        - `exclusive`: reserve screen space with the compositor
        - `normal`: compositor default behavior without forced reservation
      '';
    };
  };
  config = lib.mkIf config.user.ui.ags.bar-overlay.enable (
    let
      inherit (pkgs) astal;
      agsWithModules = pkgs.ags.override {
        extraPackages = [
          astal.tray
          astal.battery
        ];
      };

      inherit (config) user;

      astalExclusivity = builtins.getAttr user.ui.ags.bar-overlay.exclusivity {
        normal = "Astal.Exclusivity.NORMAL";
        exclusive = "Astal.Exclusivity.EXCLUSIVE";
        ignore = "Astal.Exclusivity.IGNORE";
      };

      barOverlayTsx =
        # AGS bar-overlay TSX template
        # Uses @EXCLUSIVITY@, @HOME@, and @MODULES@ as substitution placeholders
        ''
          import { App, Astal, Gtk, Gdk } from "astal/gtk3"
          import { Variable, exec, bind, monitorFile } from "astal"
          import Tray from "gi://AstalTray"
          import Battery from "gi://AstalBattery"

          const MODULES: string[] = @MODULES@
          const EXCLUSIVITY = @EXCLUSIVITY@

          const GTK_COLORS = "@HOME@/.cache/wallust/gtk-colors.css"

          const styles = `
          * {
              font-size: 14px;
              font-family: monospace;
          }

          .bar-top, .bar-bottom {
              background: transparent;
          }

          .bar-top window,
          .bar-bottom window {
              margin: 0;
              padding: 0;
          }

          .bar {
              background: transparent;
              margin: 0;
              padding: 0;
          }

          .time-block, .date-block {
              background: @bg;
              border: 0.05em solid @accent;
              padding: 0.15em 0.3em;
              margin: 0;
              color: @fg;
          }

          .time-block label, .date-block label {
              background: transparent;
              color: @fg;
              font-weight: bold;
              margin: 0;
              padding: 0;
              text-shadow:
                  0.07em 0 0.07em @black,
                  -0.07em 0 0.07em @black,
                  0 0.07em 0.07em @black,
                  0 -0.07em 0.07em @black;
          }

          .battery-block {
              background: @bg;
              border: 0.05em solid @accent;
              padding: 0.15em 0.3em;
              margin: 0;
              color: @fg;
          }

          .battery-block label {
              background: transparent;
              color: @fg;
              font-weight: bold;
              margin: 0;
              padding: 0;
              text-shadow:
                  0.07em 0 0.07em @black,
                  -0.07em 0 0.07em @black,
                  0 0.07em 0.07em @black,
                  0 -0.07em 0.07em @black;
          }

          .tray-block {
              background: @bg;
              border: 0.05em solid @accent;
              padding: 0.15em;
              margin: 0;
          }

          .tray-item {
              background: transparent;
              border: none;
              padding: 0.15em;
              margin: 0;
              min-width: unset;
              min-height: unset;
              outline: none;
              box-shadow: none;
          }

          .tray-item:hover {
              background: alpha(@fg, 0.1);
          }

          .tray-item:focus {
              outline: none;
              box-shadow: none;
          }

          .tray-item image {
              min-width: 1.15em;
              min-height: 1.15em;
          }
          `

          function loadStyles() {
              App.reset_css()
              App.apply_css(GTK_COLORS)
              App.apply_css(styles)
          }

          // Watch colors file for changes
          monitorFile(GTK_COLORS, () => {
              loadStyles()
          })

          const time = Variable("").poll(1000, () => exec(["date", "+%H:%M:%S"]))
          const date = Variable("").poll(30000, () => exec(["date", "+%d/%m/%y"]))

          const tray = Tray.get_default()
          const battery = Battery.get_default()

          function TrayItem({ item }: { item: any }) {
              const handleClick = (self: any, event: Gdk.Event) => {
                  const button = event.get_button()[1]
                  if (button === Gdk.BUTTON_PRIMARY) {
                      item.activate(event.get_coords()[1], event.get_coords()[2])
                  }
              }

              return <button
                  className="tray-item"
                  tooltipMarkup={bind(item, "tooltipMarkup")}
                  onButtonPressEvent={handleClick}>
                  <icon gIcon={bind(item, "gicon")} />
              </button>
          }

          function BatteryBlock() {
              return <box className="battery-block" spacing={4}>
                  <label
                      label={bind(battery, "percentage").as(
                          (p) => `''${Math.round(p * 100)}%`
                      )}
                  />
                  <label
                      label={bind(battery, "charging").as((c) => (c ? "↑" : "↓"))}
                  />
              </box>
          }

          function BarContent() {
              return <box className="bar" spacing={8}>
                  {MODULES.includes("battery") && <BatteryBlock />}
                  {MODULES.includes("time") && <box className="time-block">
                      <label label={time()} />
                  </box>}
                  {MODULES.includes("date") && <box className="date-block">
                      <label label={date()} />
                  </box>}
                  {MODULES.includes("tray") && <box className="tray-block" spacing={2}>
                      {bind(tray, "items").as(items => items.map(item => (
                          <TrayItem key={item.itemId} item={item} />
                      )))}
                  </box>}
              </box>
          }

          function TopBar() {
              return <window
                  className="bar-top"
                  layer={Astal.Layer.OVERLAY}
                  exclusivity={EXCLUSIVITY}
                  anchor={Astal.WindowAnchor.TOP}
                  application={App}>
                  <BarContent />
              </window>
          }

          function BottomBar() {
              return <window
                  className="bar-bottom"
                  layer={Astal.Layer.OVERLAY}
                  exclusivity={EXCLUSIVITY}
                  anchor={Astal.WindowAnchor.BOTTOM}
                  application={App}>
                  <BarContent />
              </window>
          }

          App.start({
              main() {
                  loadStyles()
                  TopBar()
                  BottomBar()
              },
          })
        '';

      tsconfigData = {
        compilerOptions = {
          allowJs = true;
          esModuleInterop = true;
          forceConsistentCasingInFileNames = true;
          jsx = "react-jsx";
          jsxImportSource = "astal/gtk3/jsx-runtime";
          lib = ["ES2022"];
          module = "ES2022";
          moduleResolution = "node";
          skipLibCheck = true;
          strict = true;
          target = "ES2022";
        };
        exclude = ["node_modules"];
        include = ["**/*.ts" "**/*.tsx"];
      };
    in {
      user.ui.ags.package = agsWithModules;
      environment.systemPackages = [
        agsWithModules
      ];
      bayt.users."${config.user.name}" = {
        files = {
          ".config/ags/bar-overlay.tsx".text =
            builtins.replaceStrings
            ["@EXCLUSIVITY@" "@HOME@" "@MODULES@"]
            [astalExclusivity "/home/${user.name}" (builtins.toJSON user.ui.ags.bar-overlay.modules)]
            barOverlayTsx;
          ".config/ags/tsconfig.json" = {
            generator = lib.generators.toJSON {};
            value = tsconfigData;
          };
        };
      };
    }
  );
}
