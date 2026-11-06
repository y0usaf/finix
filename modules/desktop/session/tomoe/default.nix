{
  config,
  lib,
  pkgs,
  inputPackages,
  generators,
  ...
}: let
  mkLispInline = form:
    if lib.isString form && builtins.match "[[:space:]]*" form == null
    then {__toLispInline = form;}
    else throw "mkLispInline: expected a nonblank string";

  probeLisp = generators.lisp.render (import ./lisp/probe.data.nix generators.lisp);

  lispList = items:
    if items == []
    then "nil"
    else "(list ${lib.concatStringsSep " " items})";

  lispAttrs = v: let
    present = lib.filterAttrs (_: x: x != null) v;
    entries = lib.mapAttrsToList (k: x: ":|${lib.replaceStrings ["\\" "|"] ["\\\\" "\\|"] (lib.toUpper k)}| ${toLisp x}") present;
  in
    if builtins.length entries != builtins.length (lib.unique (map lib.toUpper (builtins.attrNames present)))
    then throw "toLisp: keys collide after ASCII uppercasing"
    else lispList entries;

  lispFloat = v: let
    json = builtins.toJSON v;
  in
    if json == "null"
    then throw "toLisp: cannot serialize a non-finite float"
    else if builtins.match ".*[eE].*" json != null
    then lib.replaceStrings ["e" "E"] ["d" "d"] json
    else "${json}d0";

  lispByType = {
    set = v: v.__toLispInline or (lispAttrs v);
    list = v: lispList (map toLisp v);
    string = v: ''"${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] v}"'';
    path = v: toLisp "${v}";
    null = _: "nil";
    bool = v:
      if v
      then "t"
      else "nil";
    int = toString;
    float = lispFloat;
  };

  toLisp = v: lispByType.${builtins.typeOf v} or (throw "toLisp: cannot serialize ${builtins.typeOf v}") v;

  inherit (config.user) defaults;
  cfg = config.user.ui.tomoe;
  inherit (cfg) bar;

  keyword = name: mkLispInline ":${name}";
  binding = modifiers: key: command: description:
    [(map keyword modifiers) key (keyword command)]
    ++ lib.optionals (description != null) [(keyword "description") description];

  layouts = {
    deck = {
      text = generators.lisp.render (import ./lisp/deck.data.nix generators.lisp);
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
      text = generators.lisp.render (import ./lisp/sway.data.nix generators.lisp);
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
    inherit (lib.genAttrs ["discord" "steam" "obs"] (name: [name])) discord steam obs;
    terminal = ["tern"];
    launcher = ["sh" "-c" defaults.launcher];
    files = ["pcmanfm"];
    volume-up = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
    volume-down = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
    volume-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
    mic-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
  };

  palette = "${config.user.homeDirectory}/.cache/theme/gtk.css";

  frameTick = 33;

  hudParameters = {
    font = "monospace, Bold";
    icon-font = "Symbols Nerd Font";
    emoji-font = "Noto Color Emoji";
    height = 30;
    shadow = 3;
  };

  gaps = 8;

  seam =
    if bar.style == "spine"
    then builtins.ceil (28.0 * bar.scale) + 2 * gaps
    else gaps;

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

  gapParameters = {
    inherit (barParameters) modules center-between edges inset time date hot media-width;
    font = config.user.ui.fonts.mainFontName;
    inherit (bar) scale;
    sample = 1000;
  };

  cassetteParameters =
    {
      inherit (gapParameters) modules center-between edges inset time date hot media-width font scale sample;
      segments = 10;
    }
    // (
      if bar.style == "spine"
      then {
        colors = {
          dark = spineColors;
          light = spineLightColors;
        };
        spine-title = 12;
      }
      else {
        colors = {
          dark = cassetteColors;
          light = cassetteColors;
        };
      }
    );

  glassParameters = {
    inherit (config.user.appearance.glass) passes offset;
  };

  glassAlpha = lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (config.user.appearance.glass.opacity * 255 + 0.5)));

  spineLightColors = {
    face = "#FFFFFF" + glassAlpha;
    shine = "#FFFFFF59";
    shade = "#0000001F";
    ink = "#292928";
    dim = "#6E6A62";
    groove = "#0000001F";
    hole = "#00000038";
    lcd = "#C2C8B6";
    rim = "#0000002E";
    ghost = "#B3B9A6";
    counter = "#0B0B0CCC";
    counter-ghost = "#2B2A27";
    amber = "#F5A833";
    orange = "#ED5C1C";
    teal = "#218C87";
    green = "#5E8F2E";
    red = "#D63C1A";
    led-off = "#0000001A";
    paper = "#FFFFFF33";
    tape = "#5A4636";
    shadow = "#00000026";
  };

  barLisp = let
    cassetteLisp = deck:
      "(defparameter +cassette+ ${toLisp cassetteParameters})\n"
      + probeLisp
      + generators.lisp.render (import ./lisp/cassette.data.nix generators.lisp)
      + deck;
  in {
    panels = "(defparameter +bar+ ${toLisp barParameters})\n" + generators.lisp.render (import ./lisp/bar.data.nix generators.lisp);
    gap = "(defparameter +gap+ ${toLisp gapParameters})\n" + probeLisp + generators.lisp.render (import ./lisp/gap.data.nix generators.lisp);
    cassette = cassetteLisp (generators.lisp.render (import ./lisp/plates.data.nix generators.lisp));
    spine = cassetteLisp (generators.lisp.render (import ./lisp/spine.data.nix generators.lisp));
  };

  spineColors = {
    face = "#000000" + glassAlpha;
    shine = "#FFFFFF14";
    shade = "#00000066";
    ink = "#ECE7DC";
    dim = "#9A958A";
    groove = "#FFFFFF1F";
    hole = "#FFFFFF38";
    lcd = "#1A1C17";
    rim = "#FFFFFF2E";
    ghost = "#2A2D25";
    counter = "#0B0B0CCC";
    counter-ghost = "#2B2A27";
    amber = "#F5A833";
    orange = "#ED5C1C";
    teal = "#2BB0A8";
    green = "#7DB343";
    red = "#E5482A";
    led-off = "#FFFFFF1A";
    paper = "#00000033";
    tape = "#9C7B5E";
    shadow = "#00000059";
  };

  cassetteColors = {
    face = "#E9E5DC";
    shine = "#FBFAF6";
    shade = "#BDB7AA";
    ink = "#292928";
    dim = "#6E6A62";
    groove = "#B4AE9F";
    hole = "#3C3A37";
    lcd = "#C2C8B6";
    rim = "#7D8273";
    ghost = "#B3B9A6";
    counter = "#1F1F1E";
    counter-ghost = "#3A3935";
    amber = "#F5A833";
    orange = "#ED5C1C";
    teal = "#218C87";
    green = "#5E8F2E";
    red = "#D63C1A";
    led-off = "#D2CDC0";
    paper = "#F7F4ED";
    tape = "#5A4636";
    shadow = "#29292859";
  };

  shaderDir = "${inputPackages.tomoe.default}/share/tomoe/examples/shaders";

  shaderWallpaperParameters = {
    shaders = map (entry: lib.take 2 entry ++ [(config.user.theme.apply (lib.last entry))]) [
      ["${generators.sourceFile "cassette-squares.glsl" (import ./shaders/cassette-squares.data.nix)}" 30 "light"]
      ["${generators.sourceFile "cassette-led.glsl" (import ./shaders/cassette-led.data.nix)}" 30 "light"]
      ["${generators.sourceFile "hex-spiral.glsl" (import ./shaders/hex-spiral.data.nix)}" 30 "dark"]
      ["${generators.sourceFile "dot-corridor.glsl" (import ./shaders/dot-corridor.data.nix)}" 30 "dark"]
      ["${generators.sourceFile "su-ei.glsl" (import ./shaders/su-ei.data.nix)}" 30 "light"]
      ["${generators.sourceFile "glass-mound.glsl" (import ./shaders/glass-mound.data.nix)}" 30 "light"]
      ["${generators.sourceFile "llama-herd.glsl" (import ./shaders/llama-herd.data.nix)}" 240 "light"]
      ["${generators.sourceFile "llama-herd-night.glsl" (import ./shaders/llama-herd-night.data.nix)}" 240 "dark"]
      ["${shaderDir}/liquify.glsl" 30 "light"]
      ["${shaderDir}/okazz-spheres.glsl" 30 "dark"]
      ["${generators.sourceFile "balatro.glsl" (import ./shaders/balatro.data.nix)}" 30 "dark"]
      ["${shaderDir}/xmb.glsl" 30 "dark"]
      ["${shaderDir}/aurora.glsl" 30 "dark"]
      ["${shaderDir}/stars.glsl" 24 "dark"]
      ["${shaderDir}/towers.glsl" 24 "dark"]
      ["${shaderDir}/cubes.glsl" 30 "dark"]
      ["${shaderDir}/okazz-glyphs.glsl" 30 "dark"]
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

  kenneyInterfaceSounds = pkgs.fetchzip {
    name = "kenney-interface-sounds";
    url = "https://opengameart.org/sites/default/files/kenney_interfaceSounds.zip";
    stripRoot = false;
    hash = "sha256-nwNQDiuUl1yr3Axbw2FLA1MHSipHz4BE/iS+DW7ed4M=";
  };

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
      ffmpeg -v error -i ${kenneyInterfaceSounds}/Audio/click_00$i.ogg -ar 48000 -ac 2 -c:a pcm_s16le $out/click-$i.wav
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
      style = lib.mkOption {
        type = lib.types.enum ["panels" "gap" "cassette" "spine"];
        default = "panels";
        description = "panels: framed boxes floating over the screen edges. gap: one line of text inside the 8px window gap, covering nothing. cassette: two putty deck plates hanging from the screen edge either side of the centre, with LCD readouts, LED ladders, a tape counter clock and a J-card for media, in a fixed palette that ignores the colour scheme. spine: the same parts, inked for the light or dark theme, on one vertical J-card spine standing between the deck's two columns, which widen their seam for it and carry it along when they move; on outputs narrower than 21:9, where the deck has one column, the modules hang as two plates instead, across the top and bottom of a published focal frame or else at the screen edges.";
      };

      modules = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu" "vram" "media" "frame"]);
        default = ["time" "date"];
        description = "Bar overlay modules to render.";
      };

      edges = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["top" "bottom"]);
        default = ["top" "bottom"];
        description = "Screen edges that get a module bar. Single edge = no duplicated widgets.";
      };

      scale = lib.mkOption {
        type = lib.types.numbers.positive;
        default = 1;
        description = "Gap bar size multiplier: text, meters, gaps and offsets grow with it.";
      };
    };
  };

  config.user.files.".config/tomoe/init.lisp".text = lib.concatStringsSep "\n" [
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
      (defparameter +policy-terminal+ ${toLisp {app-id = "so.stencil.tern";}})
      (defparameter +policy-bindings+ ${toLisp userBindings})
      (defparameter +policy-launches+ ${toLisp launches})
      (defparameter +layout+ ${toLisp ({
          inherit gaps seam;
          float-ratio = mkLispInline "3/5";
        }
        // layout.parameters)})
      (defparameter +layout-bindings+ ${toLisp (layout.bindings ++ [(binding ["alt"] "t" "terminal" "Terminal")])})
    ''
    (generators.lisp.render (import ./lisp/policy.data.nix generators.lisp))
    layout.text
    (generators.lisp.render (import ./lisp/user.data.nix generators.lisp))
    "(defparameter +hud+ ${toLisp hudParameters})"
    (generators.lisp.render (import ./lisp/hud.data.nix generators.lisp))
    "(defparameter +hud-theme+ ${toLisp hudThemeParameters})"
    (generators.lisp.render (import ./lisp/theme.data.nix generators.lisp))
    "(defparameter +glass+ ${toLisp glassParameters})"
    (generators.lisp.render (import ./lisp/glass.data.nix generators.lisp))
    barLisp.${bar.style}
    "(defparameter +shader-wallpaper+ ${toLisp shaderWallpaperParameters})"
    (generators.lisp.render (import ./lisp/shader-wallpaper.data.nix generators.lisp))
    "(defparameter +peek+ ${toLisp peekParameters})"
    (generators.lisp.render (import ./lisp/peek.data.nix generators.lisp))
    "(defparameter +sounds+ ${toLisp soundParameters})"
    (generators.lisp.render (import ./lisp/sounds.data.nix generators.lisp))
    cfg.extraConfig
  ];
}
