{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  mkLispInline = form:
    if lib.isString form && builtins.match "[[:space:]]*" form == null
    then {__toLispInline = form;}
    else throw "mkLispInline: expected a nonblank string";

  toLisp = v:
    if lib.isAttrs v && v ? __toLispInline
    then v.__toLispInline
    else if lib.isAttrs v
    then let
      present = lib.filterAttrs (_: x: x != null) v;
      entries = lib.mapAttrsToList (k: x: ":|${lib.replaceStrings ["\\" "|"] ["\\\\" "\\|"] (lib.toUpper k)}| ${toLisp x}") present;
    in
      if builtins.length entries != builtins.length (lib.unique (map lib.toUpper (builtins.attrNames present)))
      then throw "toLisp: keys collide after ASCII uppercasing"
      else if entries == []
      then "nil"
      else "(list ${lib.concatStringsSep " " entries})"
    else if lib.isList v
    then
      if v == []
      then "nil"
      else "(list ${lib.concatStringsSep " " (map toLisp v)})"
    else if lib.isString v
    then ''"${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] v}"''
    else if builtins.isPath v
    then toLisp "${v}"
    else if v == null
    then "nil"
    else if lib.isBool v
    then
      if v
      then "t"
      else "nil"
    else if lib.isInt v
    then toString v
    else if lib.isFloat v
    then let
      json = builtins.toJSON v;
    in
      if json == "null"
      then throw "toLisp: cannot serialize a non-finite float"
      else if builtins.match ".*[eE].*" json != null
      then lib.replaceStrings ["e" "E"] ["d" "d"] json
      else "${json}d0"
    else throw "toLisp: cannot serialize ${builtins.typeOf v}";

  inherit (config.user) defaults;
  cfg = config.user.ui.tomoe;
  inherit (cfg) bar;

  keyword = name: mkLispInline ":${name}";
  binding = modifiers: key: command: description:
    [(map keyword modifiers) key (keyword command)]
    ++ lib.optionals (description != null) [(keyword "description") description];

  terminalAppId = "ekko-term";

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
    cursor = ["cursor"];
    browser = [defaults.browser];
    discord = ["discord"];
    steam = ["steam"];
    obs = ["obs"];
    terminal = [defaults.terminal "--app-id" terminalAppId];
    launcher = ["sh" "-c" defaults.launcher];
    files = ["pcmanfm"];
    editor = [defaults.terminal "-e" "nvim"];
    volume-up = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
    volume-down = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
    volume-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
    mic-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
  };

  palette = "${config.user.homeDirectory}/.cache/wallust/gtk-colors.css";

  barParameters = {
    modules = map keyword bar.modules;
    center-between = map keyword ["time" "date"];
    edges = map keyword bar.edges;
    inherit (bar) exclusive indent;
    font = "monospace, Bold";
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
      cpu.interval = 1000;
      memory.interval = 2000;
      gpu.interval = 2000;
    };
    show = {
      cpu-temp = true;
      gpu-temp = true;
      gpu-vram = true;
      memory-absolute = false;
    };
  };

  bongoParameters = {
    height = 80;
    margin-bottom = 6;
    x-offset = -24;
    duration = 100;
    frames = "${./assets/bongo-cat}";
  };

  shaderDir = "${flakeInputs.tomoe.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/tomoe/examples/shaders";

  shaderWallpaperParameters = {
    shaders = [
      ["${shaderDir}/flow.glsl" 15]
      ["${shaderDir}/stars.glsl" 20]
      ["${shaderDir}/grain.glsl" 12]
      ["${shaderDir}/cubes.glsl" 30]
    ];
    bind = binding ["alt" "shift"] "b" "next" "Next Wallpaper";
  };
in {
  options.user.ui.tomoe = {
    layout = lib.mkOption {
      type = lib.types.enum ["deck" "sway"];
      default = "deck";
      description = ''
        Window-management layout generated into ~/.config/tomoe/init.lisp:
        "deck" = two 16:9 deck columns (the original ultrawide layout);
        "sway" = manual h/v split trees over numbered workspaces
        (Alt+J/K scroll workspaces, Alt+H/L focus left/right).
      '';
    };

    displays = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
      description = ''
        Per-output configure-output keywords, keyed by output name: `mode`
        ([W H] or [W H Hz]), `refresh`, `scale`, `position` ([X Y] physical
        pixels), `disabled`, `mirror`, `vrr`, `icc` (an ICC profile path). An
        empty attrset means tomoe uses EDID-preferred modes for every output.
      '';
      example = lib.literalExpression ''
        {
          "DP-1" = { mode = [5120 1440]; position = [0 0]; vrr = true; };
          "eDP-1".disabled = true;
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Common Lisp appended to the generated ~/.config/tomoe/init.lisp.";
    };

    bar = {
      modules = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu"]);
        default = ["time" "date"];
        description = "Bar overlay modules to render.";
      };

      edges = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["top" "bottom"]);
        default = ["top" "bottom"];
        description = "Screen edges that get a module bar. Single edge = no duplicated widgets.";
      };

      indent = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 0;
        description = "Exclusive bars: lift the widget row this many px off the screen edge. Baked into the bar thickness so the exclusive zone covers it — windows never overlap the gap.";
      };

      exclusive = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the bar reserves exclusive space that windows tile around. Keep false for a pure overlay.";
      };
    };
  };

  config.manzil.users."${config.user.name}".files.".config/tomoe/init.lisp".text = lib.concatStringsSep "\n" [
    ''
      (in-package #:tomoe-user)
      (defparameter +policy-displays+ ${toLisp (lib.mapAttrsToList (name: settings: [name] ++ lib.concatLists (lib.mapAttrsToList (key: value: [(keyword key) value]) settings)) cfg.displays)})
      (defparameter +policy-settings+ ${toLisp ({honor-xdg-activation-with-invalid-serial = true;} // lib.optionalAttrs config.hardware.nvidia.enable {wait-for-frame-completion = true;})})
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
    "(defparameter +bar+ ${toLisp barParameters})"
    (builtins.readFile ./lisp/bar.lisp)
    "(defparameter +bongo-cat+ ${toLisp bongoParameters})"
    (builtins.readFile ./lisp/bongo-cat.lisp)
    "(defparameter +shader-wallpaper+ ${toLisp shaderWallpaperParameters})"
    (builtins.readFile ./lisp/shader-wallpaper.lisp)
    cfg.extraConfig
  ];
}
