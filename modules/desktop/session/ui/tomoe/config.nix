{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.generators) mkLispInline toLisp;
  inherit (config.user) defaults;
  cfg = config.user.ui.tomoe;
  inherit (cfg) bar;
  inherit (bar) sysinfo;

  keyword = name: mkLispInline ":${name}";
  plist = attrs: lib.concatLists (lib.mapAttrsToList (name: value: [(keyword name) value]) attrs);
  binding = modifiers: key: command: description:
    [(map keyword modifiers) key (keyword command)]
    ++ lib.optionals (description != null) [(keyword "description") description];

  terminalAppId = "ekko-term";
  wallpaper = ''swaybg -i "$(find ${lib.escapeShellArg config.user.paths.wallpapers.static.path} -type f | shuf -n 1)" -m fill'';

  layouts = {
    deck = {
      file = ./lisp/deck.lisp;
      parameters.ratios = map mkLispInline ["1/2" "21/32" "11/32"];
      bindings = [
        (binding ["alt"] "h" "focus-left" "Focus Left Column")
        (binding ["alt"] "l" "focus-right" "Focus Right Column")
        (binding ["alt"] "j" "scroll-down" "Scroll Deck Down")
        (binding ["alt"] "k" "scroll-up" "Scroll Deck Up")
        (binding ["alt" "shift"] "h" "swap-columns" "Swap Columns")
        (binding ["alt" "shift"] "l" "swap-columns" null)
        (binding ["alt" "shift"] "j" "move-down" "Move Window Down")
        (binding ["alt" "shift"] "k" "move-up" "Move Window Up")
        (binding ["alt"] "bracketleft" "to-left" "Move Window to Left Column")
        (binding ["alt"] "bracketright" "to-right" "Move Window to Right Column")
        (binding ["alt"] "o" "grid" "Toggle Even Grid")
        (binding ["alt"] "r" "ratio" "Cycle Column Split (16:9+16:9 / 21:9+11:9 / 11:9+21:9)")
        (binding ["alt"] "f" "fullscreen" "Toggle Fullscreen")
        (binding ["super"] "space" "floating" "Toggle Floating")
        (binding ["super"] "Tab" "next" null)
        (binding ["super" "shift"] "Tab" "previous" null)
      ];
    };
    sway = {
      file = ./lisp/sway.lisp;
      parameters.workspaces = 9;
      bindings = [
        (binding ["alt"] "h" "focus-left" "Focus Left")
        (binding ["alt"] "l" "focus-right" "Focus Right")
        (binding ["alt" "control"] "j" "focus-down" "Focus Down")
        (binding ["alt" "control"] "k" "focus-up" "Focus Up")
        (binding ["alt"] "j" "workspace-next" "Next Workspace")
        (binding ["alt"] "k" "workspace-previous" "Previous Workspace")
        (binding ["alt" "shift"] "j" "move-next" "Move Window to Next Workspace")
        (binding ["alt" "shift"] "k" "move-previous" "Move Window to Previous Workspace")
        (binding ["alt" "shift"] "h" "swap-previous" "Swap with Previous Window")
        (binding ["alt" "shift"] "l" "swap-next" "Swap with Next Window")
        (binding ["alt"] "b" "split-horizontal" "Split Next Horizontally")
        (binding ["alt"] "v" "split-vertical" "Split Next Vertically")
        (binding ["alt"] "f" "fullscreen" "Toggle Fullscreen")
        (binding ["super"] "space" "floating" "Toggle Floating")
      ];
    };
  };
  layout = layouts.${cfg.layout};

  userBindings =
    [
      (binding ["alt"] "1" "cursor" null)
      (binding ["alt"] "2" "browser" null)
      (binding ["alt"] "3" "discord" null)
      (binding ["alt"] "4" "steam" null)
      (binding ["alt"] "5" "obs" null)
      (binding ["alt"] "9" "power" "Blank/Restore All Outputs")
      (binding ["super"] "r" "launcher" "Run an Application")
      (binding ["alt"] "e" "files" "File Manager")
      (binding ["super" "shift"] "o" "editor" "Editor")
      (binding ["alt"] "q" "close" "Close Window")
      (binding ["alt" "shift"] "e" "quit" null)
      (binding ["alt"] "g" "screenshot" "Screenshot")
      (binding ["alt" "shift"] "g" "screenshot-screen" "Screenshot Screen")
      (binding ["alt" "shift"] "c" "wallpaper" "Random Wallpaper")
    ]
    ++ lib.mapAttrsToList (key: command: binding [] key command null) {
      XF86AudioRaiseVolume = "volume-up";
      XF86AudioLowerVolume = "volume-down";
      XF86AudioMute = "volume-mute";
      XF86AudioMicMute = "mic-mute";
      XF86AudioPlay = "play-pause";
      XF86AudioNext = "track-next";
      XF86AudioPrev = "track-prev";
      XF86MonBrightnessUp = "brightness-up";
      XF86MonBrightnessDown = "brightness-down";
    };

  launches = lib.mapAttrsToList (command: argv: [command argv]) {
    cursor = [defaults.ide];
    browser = [defaults.browser];
    discord = [defaults.discord];
    steam = ["steam"];
    obs = ["obs"];
    terminal = [defaults.terminal "--app-id" terminalAppId];
    launcher = ["sh" "-c" defaults.launcher];
    files = [defaults.fileManager];
    editor = [defaults.terminal "-e" defaults.editor];
    wallpaper = ["sh" "-c" "killall swaybg; ${wallpaper} &"];
    volume-up = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
    volume-down = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
    volume-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
    mic-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
    play-pause = ["playerctl" "play-pause"];
    track-next = ["playerctl" "next"];
    track-prev = ["playerctl" "previous"];
    brightness-up = ["brightnessctl" "set" "5%+"];
    brightness-down = ["brightnessctl" "set" "5%-"];
  };

  sampler = pkgs.writeShellScript "tomoe-sysinfo" (builtins.readFile ./sysinfo.sh);
  palette = "${config.user.homeDirectory}/.cache/wallust/gtk-colors.css";

  barParameters = {
    modules = map keyword bar.modules;
    center-between = lib.mapNullable (map keyword) bar.center-between;
    edges = map keyword bar.edges;
    inherit (bar) exclusive indent;
    font = "${lib.defaultTo "monospace" bar.font-family}, Bold";
    height = 24;
    spacing = 8;
    label-size = 14;
    label-gap = 4;
    border = 1;
    padding = [2.1 4.2 2.1 4.2];
    widths = {
      battery = 58;
      time = 74;
      date = 74;
      network = 96;
      cpu = 104;
      memory = 84;
      gpu = 150;
    };
    time = "%H:%M:%S";
    date = "%d/%m/%y";
    clock-interval = 1000;
    palette-file = palette;
    palette-command = "mkdir -p ${lib.escapeShellArg (dirOf palette)} && { cat ${lib.escapeShellArg palette} 2>/dev/null || true; }";
    sysinfo = {
      cpu = {
        command = "${sampler} cpu";
        interval = sysinfo.cpu-interval;
      };
      memory = {
        command = "${sampler} memory";
        interval = sysinfo.memory-interval;
      };
      gpu = {
        command = "${sampler} gpu ${sysinfo.gpu-backend} ${lib.escapeShellArg (lib.defaultTo "" sysinfo.gpu-card)}";
        interval = sysinfo.gpu-interval;
      };
    };
    show = {
      cpu-temp = sysinfo.show-cpu-temp;
      gpu-temp = sysinfo.show-gpu-temp;
      gpu-vram = sysinfo.show-gpu-vram;
      memory-absolute = sysinfo.memory-style == "absolute";
    };
  };

  bongoParameters = {
    inherit (bar.bongo-cat) height margin-bottom x-offset;
    duration = bar.bongo-cat.keypress-duration;
    frames = "${./assets/bongo-cat}";
  };

  initText = lib.concatStringsSep "\n" ([
      ''
        (in-package #:tomoe-user)
        (defparameter +policy-displays+ ${toLisp (lib.mapAttrsToList (name: settings: [name] ++ plist settings) cfg.displays)})
        (defparameter +policy-settings+ ${toLisp cfg.settings})
        (defparameter +policy-wallpaper+ ${toLisp wallpaper})
        (defparameter +policy-launcher+ ${toLisp {
          app-id = "launcher";
          ratio = mkLispInline "1/3";
        }})
        (defparameter +policy-hidden-window+ ${toLisp {
          app-id = "steam_proton";
          title-prefix = "Lovely";
        }})
        (defparameter +policy-terminal+ ${toLisp {
          app-id = terminalAppId;
          title-prefix = "ekko";
        }})
        (defparameter +policy-bindings+ ${toLisp userBindings})
        (defparameter +policy-launches+ ${toLisp launches})
        (defparameter +layout+ ${toLisp ({
            gaps = 8;
            float-ratio = mkLispInline "3/5";
          }
          // layout.parameters)})
        (defparameter +layout-bindings+ ${toLisp (layout.bindings ++ [(binding ["alt"] "t" "terminal" "Terminal")])})
      ''
      (builtins.readFile ./lisp/policy.lisp)
      (builtins.readFile layout.file)
      (builtins.readFile ./lisp/user.lisp)
    ]
    ++ lib.optionals bar.enable [
      "(defparameter +bar+ ${toLisp barParameters})"
      (builtins.readFile ./lisp/bar.lisp)
    ]
    ++ lib.optionals (bar.enable && bar.bongo-cat.enable) [
      "(defparameter +bongo-cat+ ${toLisp bongoParameters})"
      (builtins.readFile ./lisp/bongo-cat.lisp)
    ]
    ++ [cfg.extraConfig]);
in {
  user.ui.tomoe = {
    lisp = {inherit initText;};
    settings.wait-for-frame-completion = lib.mkIf config.hardware.nvidia.enable (lib.mkDefault true);
  };
}
