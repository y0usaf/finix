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

  frameTick = 33;

  hudParameters = {
    font = "monospace, Bold";
    icon-font = "Symbols Nerd Font";
    emoji-font = "Noto Color Emoji";
    height = 30;
    shadow = 3;
  };

  hudThemeParameters = {
    palette-file = palette;
    palette-command = "mkdir -p ${lib.escapeShellArg (dirOf palette)} && { cat ${lib.escapeShellArg palette} 2>/dev/null || true; }";
    border = 2;
    focus-flash = 220;
    tick = frameTick;
  };

  barParameters = {
    modules = map keyword bar.modules;
    center-between = map keyword ["time" "date"];
    edges = map keyword bar.edges;
    inherit (bar) exclusive indent;
    margin = 6;
    gap = 8;
    inset = 84;
    time = "%H:%M";
    date = "%a %d %b";
    clock-tick = 200;
    tick = frameTick;
    sample = {
      cpu = 500;
      memory = 1000;
      gpu = 1000;
    };
    segments = 12;
    history = 28;
    tau = 0.11;
    flash = 400;
    hot = 80;
    media-width = 34;
  };

  bongoParameters = {
    height = 80;
    margin-bottom = 6;
    x-offset = -24;
    duration = 100;
    idle = 60000;
    groove = 380;
    strip = 32;
    bounce = 6;
    bounce-ms = 260;
    tick = frameTick;
    frames = "${./assets/bongo-cat}";
  };

  comboParameters = {
    hands = [
      [800 "FLUSH FIVE" 16 (keyword "color3")]
      [500 "FIVE OF A KIND" 12 (keyword "color1")]
      [300 "STRAIGHT FLUSH" 8 (keyword "color5")]
      [200 "FOUR OF A KIND" 7 (keyword "color1")]
      [140 "FULL HOUSE" 4 (keyword "color3")]
      [100 "FLUSH" 4 (keyword "color5")]
      [70 "STRAIGHT" 4 (keyword "color2")]
      [45 "THREE OF A KIND" 3 (keyword "color6")]
      [25 "TWO PAIR" 2 (keyword "color4")]
      [10 "PAIR" 2 (keyword "color4")]
      [0 "HIGH CARD" 1 (keyword "color8")]
    ];
    window = 1200;
    show = 3;
    cash-min = 5;
    hold = 2400;
    roll = 600;
    pop = 160;
    shake = 320;
    fire = 7;
    drain-width = 160;
    offset = 104;
    side = 240;
    lift = 52;
    tick = frameTick;
  };

  shaderDir = "${flakeInputs.tomoe.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/tomoe/examples/shaders";

  shaderWallpaperParameters = {
    shaders = [
      ["${./shaders/balatro.glsl}" 30]
      ["${shaderDir}/xmb.glsl" 30]
      ["${shaderDir}/aurora.glsl" 30]
      ["${shaderDir}/stars.glsl" 24]
      ["${shaderDir}/towers.glsl" 24]
      ["${shaderDir}/cubes.glsl" 30]
    ];
    preview = {
      width = 256;
      height = 144;
      gap = 24;
      border = 4;
    };
    bind = binding ["alt" "shift"] "b" "menu" "Choose Wallpaper";
  };

  peekParameters.bind = binding ["alt"] "p" "toggle" "Peek at the Desktop";

  switchClick = pkgs.fetchurl {
    url = "https://quicksounds.com/uploads/tracks/918151184_174749704_164721627.mp3";
    hash = "sha256-Amji9hOtJveumg4xb4ulHVerGnYbQ8KbfVkOKQfUs7Y=";
  };

  switchButton = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/TOM-BadEN/Nintendo-Switch-Sounds-Effect/70614a3e0b912068476ed54d9836d08e8d6878b0/WAV/SeVgc_Info_OperateOthers.wav";
    hash = "sha256-X581tiK275PT9+6O8V1HKc69zDmNllrEcIcKm7xk9xs=";
  };

  sounds = pkgs.runCommand "tomoe-sounds" {nativeBuildInputs = [pkgs.ffmpeg];} ''
    mkdir $out
    for i in 1 2 3; do
      ffmpeg -v error -i ${./assets/sounds}/click_00$i.ogg -ar 48000 -ac 2 -c:a pcm_s16le $out/click-$i.wav
    done
    ffmpeg -v error -i ${switchClick} -ar 48000 -ac 2 -c:a pcm_s16le \
      -af 'silenceremove=start_periods=1:start_threshold=-50dB,atrim=0:0.45,afade=t=out:st=0.35:d=0.1' $out/close.wav
  '';

  soundParameters = {
    key = map (i: "${sounds}/click-${toString i}.wav") [1 2 3];
    key-gain = -18;
    button = "${switchButton}";
    button-gain = -23.3;
    close = "${sounds}/close.wav";
    close-gain = -6;
  };
in {
  config.user.dev.prompts.host = ["`TOMOE_SOCKET`, `WAYLAND_DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` in your environment point at the live tomoe session and its bus."];

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
        type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu" "vram" "media"]);
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
      (defparameter +policy-settings+ ${toLisp ({
          honor-xdg-activation-with-invalid-serial = true;
          focus-follows-mouse = true;
          pointer-follows-focus = true;
        }
        // lib.optionalAttrs config.hardware.nvidia.enable {wait-for-frame-completion = true;})})
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
    "(defparameter +hud+ ${toLisp hudParameters})"
    (builtins.readFile ./lisp/hud.lisp)
    "(defparameter +hud-theme+ ${toLisp hudThemeParameters})"
    (builtins.readFile ./lisp/theme.lisp)
    "(defparameter +bar+ ${toLisp barParameters})"
    (builtins.readFile ./lisp/bar.lisp)
    "(defparameter +bongo-cat+ ${toLisp bongoParameters})"
    (builtins.readFile ./lisp/bongo-cat.lisp)
    "(defparameter +combo+ ${toLisp comboParameters})"
    (builtins.readFile ./lisp/combo.lisp)
    "(defparameter +shader-wallpaper+ ${toLisp shaderWallpaperParameters})"
    (builtins.readFile ./lisp/shader-wallpaper.lisp)
    "(defparameter +peek+ ${toLisp peekParameters})"
    (builtins.readFile ./lisp/peek.lisp)
    "(defparameter +sounds+ ${toLisp soundParameters})"
    (builtins.readFile ./lisp/sounds.lisp)
    cfg.extraConfig
  ];
}
