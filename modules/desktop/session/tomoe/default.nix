{
  config,
  lib,
  pkgs,
  inputPackages,
  flakeInputs,
  generators,
  ...
}: let
  tomoeKnows = name: let
    api = "${flakeInputs.tomoe.outPath}/lisp/api.lisp";
  in
    builtins.pathExists api && lib.hasInfix ":${name}" (builtins.readFile api);

  source_probe = generators.lisp.render (({
      and,
      cond,
      copy-list,
      defun,
      ecase,
      first,
      getf,
      if',
      in-package,
      kw,
      let',
      max,
      min,
      plusp,
      round,
      setf,
      uninterned,
      when,
      ...
    }: ({
      probe--sample',
      probe--gpu-p',
    }: [
      [in-package (uninterned "tomoe-user")]
      ({
        probe,
        previous,
        system,
      }: [
        defun
        probe--sample'
        [probe previous system]
        ({sample}: [
          let'
          [[sample [copy-list previous]]]
          [
            ecase
            probe
            [
              (kw "cpu")
              ({
                total,
                idle,
              }: [let' [[total [getf system (kw "cpu-total")]] [idle [getf system (kw "cpu-idle")]]] [when total ({spent}: [let' [[spent ["-" total [getf sample (kw "total") total]]]] [setf [getf sample (kw "percent")] [if' [plusp spent] [max 0 [min 100 [round ["*" 100 ["-" spent ["-" idle [getf sample (kw "idle") idle]]]] spent]]] [getf sample (kw "percent") 0]] [getf sample (kw "total")] total [getf sample (kw "idle")] idle [getf sample (kw "temp")] [getf system (kw "cpu-temperature")]]])]])
            ]
            [
              (kw "memory")
              ({
                total,
                available,
              }: [let' [[total [getf system (kw "memory-total")]] [available [getf system (kw "memory-available")]]] [when [and total [plusp total]] [setf [getf sample (kw "percent")] [round ["*" 100 ["-" total available]] total] [getf sample (kw "used")] [round ["-" total available] 1024]]]])
            ]
            [(kw "gpu") ({gpu}: [let' [[gpu [first [getf system (kw "gpus")]]]] [cond [gpu [setf [getf sample (kw "percent")] [max 0 [min 100 [getf gpu (kw "busy")]]] [getf sample (kw "used")] [getf gpu (kw "vram-used")] [getf sample (kw "total")] [getf gpu (kw "vram-total")] [getf sample (kw "temp")] [getf gpu (kw "temperature")] [getf sample (kw "failures")] 0]] [system [setf [getf sample (kw "failures")] ["1+" [getf sample (kw "failures") 0]]]]]])]
          ]
          sample
        ])
      ])
      ({gpu}: [defun probe--gpu-p' [gpu] [and [getf gpu (kw "percent")] ["<" [getf gpu (kw "failures") 0] 3]]])
    ]))
    generators.lisp);
  mkLispInline = form:
    if lib.isString form && builtins.match "[[:space:]]*" form == null
    then {__toLispInline = form;}
    else throw "mkLispInline: expected a nonblank string";

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

  launchCommands =
    {
      browser = [defaults.browser];
      launcher = ["sh" "-c" defaults.launcher];
      files = ["pcmanfm"];
      volume-up = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
      volume-down = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
      volume-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
      mic-mute = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
    }
    // lib.genAttrs ["discord" "steam" "obs"] (name: [name]);

  commandCall = command:
    if builtins.isAttrs command
    then command
    else if launchCommands ? ${command}
    then ["launch" (keyword "argv") launchCommands.${command}]
    else command;

  binding = modifiers: key: command: description:
    [(map keyword modifiers) key (commandCall command)]
    ++ lib.optionals (description != null) [(keyword "description") description];

  userCommands = [
    {
      name = "power";
      description = "Blank or restore every output.";
    }
    {
      name = "screenshot";
      description = "Screenshot a region of an output.";
    }
    {
      name = "screenshot-screen";
      description = "Screenshot a whole output.";
    }
    {
      name = "play-pause";
      description = "Pause or resume the playing media.";
    }
    {
      name = "track-next";
      description = "Play the next track.";
    }
    {
      name = "track-prev";
      description = "Play the previous track.";
    }
    {
      name = "brightness-up";
      description = "Raise the backlight by five percent.";
    }
    {
      name = "brightness-down";
      description = "Lower the backlight by five percent.";
    }
    {
      name = "close-window";
      description = "Ask a window to close.";
      arguments = "'((:window :window :description \"Window to close.\"))";
    }
  ];

  userCommandsLisp =
    "(defparameter +user-commands+\n  (list "
    + lib.concatStringsSep "\n        " (
      map
      (entry:
        "(define-command \"${entry.name}\" :description \"${entry.description}\""
        + lib.optionalString (entry ? arguments) " :arguments ${entry.arguments}"
        + ")")
      userCommands
    )
    + "))\n";

  userLisp =
    "(in-package #:tomoe-user)\n\n"
    + userCommandsLisp
    + "\n"
    + ''
      (define-extension "user" (:reads (:command :focus) :state nil) (snapshot state event)
        (declare (ignore state snapshot))
        (let ((command (and (eq (getf event :type) :command) (getf event :name))))
          (values nil
                  (append (mapcar (lambda (binding) (apply #'bind-key binding)) +policy-bindings+)
                          +user-commands+)
                  (cond
                    ((null command) nil)
                    ((equal command "power") (list (output-power :toggle)))
                    ((equal command "screenshot") (list (screenshot)))
                    ((equal command "screenshot-screen") (list (screenshot :screen)))
                    ((equal command "play-pause") (list (media-control :play-pause)))
                    ((equal command "track-next") (list (media-control :next)))
                    ((equal command "track-prev") (list (media-control :previous)))
                    ((equal command "brightness-up") (list (adjust-brightness 5)))
                    ((equal command "brightness-down") (list (adjust-brightness -5)))
                    ((equal command "close-window")
                     (list (close-window (getf (getf event :arguments) :window))))))))
    '';

  layouts = {
    deck = {
      file = ./lisp/deck.lisp;
      parameters.ratios = map mkLispInline ["1/2" "21/32" "11/32"];
      bindings = [
        (binding ["alt"] "h" "focus-left" "Focus Left Column")
        (binding ["alt"] "l" "focus-right" "Focus Right Column")
        (binding ["alt"] "j" "scroll-down" "Scroll Deck Down")
        (binding ["alt"] "k" "scroll-up" "Scroll Deck Up")
        (binding ["alt"] "Tab" "swap-columns" "Swap Columns")
        (binding ["alt" "shift"] "h" "swap-columns" null)
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
      (binding ["alt"] "q" "close-window" "Close Window")
      (binding ["alt" "shift"] "e" "quit" null)
      (binding ["alt"] "g" "screenshot" "Screenshot")
      (binding ["alt" "shift"] "g" "screenshot-screen" "Screenshot Screen")
      (binding ["super"] "q" "close-window" "Close Window")
      (binding ["super" "shift"] "slash" "toggle-hotkeys" "Show Important Hotkeys")
      (binding ["super" "shift"] "e" (mkLispInline "(invoke \"quit\" :confirm t)") "Exit")
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

  launches = lib.mapAttrsToList (command: argv: [command argv]) (launchCommands
    // {
      terminal = ["tern"];
    });

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

  borderWidth = 2;

  seam =
    {rail = 2 * borderWidth + 2 * bar.rail.channel + bar.rail.width;}.${bar.style} or gaps;

  hudThemeParameters = {
    palette-file = palette;
    palette-command = "mkdir -p ${lib.escapeShellArg (dirOf palette)} && { cat ${lib.escapeShellArg palette} 2>/dev/null || true; }";
    border = borderWidth;
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

  kitShader = name: file: pkgs.writeText "${name}.glsl" (builtins.readFile ./shaders/kit.glsl + "\n" + builtins.readFile file);

  threadBarShader =
    pkgs.writeText "thread-bar.glsl"
    (builtins.replaceStrings ["const int THEME = 132;"] ["const int THEME = 2;"]
      (builtins.readFile ./shaders/kit.glsl)
      + "\n"
      + builtins.replaceStrings
      ["const int T_MODE = THEME + 47, T_BR = THEME + 48, T_BN = THEME + 52;"]
      ["const int T_MODE = THEME + 1, T_BR = THEME + 2, T_BN = THEME + 6;"]
      (builtins.readFile ./shaders/thread.glsl));

  membraneBarShader =
    pkgs.writeText "membrane-bar.glsl"
    (builtins.replaceStrings ["const int THEME = 132;"] ["const int THEME = 2;"]
      (builtins.readFile ./shaders/kit.glsl)
      + "\n"
      + builtins.replaceStrings
      ["const int T_MODE = THEME + 59, T_BR = THEME + 48, T_BN = THEME + 52;"]
      ["const int T_MODE = THEME + 1, T_BR = THEME + 2, T_BN = THEME + 6;"]
      (builtins.readFile ./shaders/membrane.glsl));

  railThemes = [
    {
      name = "thread";
      shader = kitShader "thread" ./shaders/thread.glsl;
      barShader = threadBarShader;
      lisp = ./lisp/rail-thread.lisp;
      description = "liquid glass on a thin seam: a 34 px seam with one glass thread down its middle, 11 px wide and as tall as the cards, carrying the readings as beads on it -- the clock as hours over minutes, the date as day over month, CPU, memory, bolo's voice at the weld, the GPU and the VRAM -- each gauge bead holding a level of denser glass from its foot up to its load with a small label over its value, every bead's block centred on it. Three beads hang above the voice dot at the weld and three below, one every 118 px of the mock, so the run is symmetric about it: the time at the top, the date at the bottom, the gauges either side of the middle. The focused card wears a 5 px glass rim welded to the thread by a meniscus at the weld; every other card keeps what bar.rail.focus asks for -- a pair of hairlines, the dark one alone and dimmer, nothing at all, or nothing under a soft halo round the focused rim. One set of glass numbers serves dark and light: the backdrop frosted and refracted toward the rim, a light tint lift, a bright inner highlight on the lit side, a dark outer hairline all round, and each bead's type inked from the luminance of what lies behind it. A switch across the seam bends the thread after the new side on a damped spring while the old rim drains back into the thread and the new one fills out of the weld both ways; within a column the weld stays and the rims only drain and fill. bolo plucks the thread -- a travelling wave out from the weld, each stretch as loud as the voice was when it passed, the beads the nodes of the string, the voice bead swelling -- and the ripple runs round the focused rim, thickening and brightening it, dying away over the settle.";
    }
    {
      name = "membrane";
      shader = kitShader "membrane" ./shaders/membrane.glsl;
      barShader = membraneBarShader;
      lisp = [./lisp/rail-thread.lisp ./lisp/rail-membrane.lisp];
      description = "thread in living glass: the same seam, beads, readings, weld, rim and motion, but the glass reads as glass and grows like tissue -- its edges bend what lies beneath them, the primaries slightly apart, its body carries the windows' own blur of the backdrop, a Fresnel rim mirrors the sky and the desktop beside it, a highlight runs down the lit side and the light it gathers falls beside it; its walls are a soap film with a thin inner membrane, organelles drift in its plasm and bolo's bead is a nucleus. A switch sends a swell along the thread, the new rim buds out of the weld and the old one pearls into droplets as it drains. One set of glass numbers for both modes, +rail-membrane--glass+ in lisp/rail-membrane.lisp.";
    }
    {
      name = "morph";
      shader = ./shaders/morph.glsl;
      lisp = null;
      description = "one slab in the deck's seam, as tall as the readings it carries, cast in one material with the focused card's frame -- same colour, same thickness, welded smoothly where they meet, rounded 14px corners -- with each gauge swelling the slab's free edge by its load and the readings, clock and bolo's voice set into it in IBM Plex Mono; every other card keeps a thin darker line. A focus change across the seam hops the slab on two springs, one within a column leaves it on its side; either way, after a pause the old frame drains back into the slab and the new one fills out of it, a quick switch only pours one frame into the other. With no card holding focus -- Alt+P's peek, an empty desktop -- the old frame drains back into the slab, which lets go of the cards and stands alone in the middle of the seam as a drop around the readings, swelling and rippling on both edges, until a focused card draws it back and its frame fills out again. Bolo's turn ripples the slab's free edge, and the focused card's whole frame comes alive with it -- a ripple runs out of the weld round its perimeter, the level history laid along it, each crest swelling the frame and catching the light -- so the frame shows which card is being spoken into; every other card's line stays still. Drawn by one GPU shader that rests once nothing moves; the material, geometry and timings are +rail--cast+ and +rail--tide+ in lisp/rail.lisp.";
    }
    {
      name = "glass";
      shader = pkgs.writeText "glass.glsl" ("#define GLASS\n" + builtins.readFile ./shaders/morph.glsl);
      lisp = ./lisp/rail-glass.lisp;
      description = "morph in liquid glass: the same slab, frames, gauges, motion and voice -- the focused frame's ripple bending what lies under it and running light along its rim while bolo listens -- but the slab and the focused frame take no colour of their own and nothing from the mode: they bend what lies beneath them towards their rims, frost it and lift its colour, with light caught along their rims and a dark line just inside them, so they read over light and dark alike; only the readings' ink follows the mode, and where what is beneath sits too near it the glass darkens or brightens it, keeping its hue, until the readings stand clear. Every other card's line is etched out of what lies beneath it. The glass is +rail-glass+ in lisp/rail-glass.lisp.";
    }
  ];

  railThemeNames = map (theme: theme.name) railThemes;

  railTheme = name: let
    found = lib.filter (theme: theme.name == name) railThemes;
  in
    if found == []
    then throw "user.ui.tomoe.bar.rail.themes: no rail theme named ${name}; there is ${lib.concatStringsSep ", " railThemeNames}"
    else builtins.head found;

  screenshotShader = builtins.readFile ./shaders/screenshot-thread.glsl;
  screenshotMarks = builtins.readFile ./shaders/screenshot-thread-marks.glsl;
  screenshotColours = builtins.readFile ./shaders/screenshot-thread-colours.glsl;
  screenshotPlain =
    pkgs.writeText "screenshot-thread.glsl"
    (builtins.replaceStrings ["/*@MARKS@*/"] [""] screenshotShader);
  screenshotMarked =
    pkgs.writeText "screenshot-thread-marks.glsl"
    (builtins.replaceStrings ["/*@MARKS@*/"] [screenshotMarks] screenshotShader);
  screenshotColoured =
    pkgs.writeText "screenshot-thread-colours.glsl"
    (builtins.replaceStrings ["/*@MARKS@*/"] [screenshotColours] screenshotShader);

  tomoeCompatLisp = builtins.readFile ./lisp/tomoe-compat.lisp;

  screenshotLisp = lib.concatStrings [
    "(defparameter +screenshot-thread--shader+ \"${screenshotPlain}\")\n"
    "(defparameter +screenshot-thread--marks+ \"${screenshotMarked}\")\n"
    "(defparameter +screenshot-thread--colours+ \"${screenshotColoured}\")\n"
    (builtins.readFile ./lisp/screenshot-thread.lisp)
  ];

  railThemeLisp = let
    themes = map railTheme bar.rail.themes;
  in
    builtins.readFile ./lisp/rail-kit.lisp
    + "\n"
    + lib.concatMapStrings (file: builtins.readFile file + "\n")
    (lib.unique (lib.concatMap (theme: lib.optionals (theme.lisp != null) (lib.toList theme.lisp)) themes))
    + "(defparameter +rail-themes+ (list ${lib.concatMapStringsSep " " (theme: ":${theme.name} (list* :shader \"${theme.shader}\" :bar-shader \"${theme.barShader or theme.shader}\" +rail-${theme.name}+)") themes}))\n";

  railParameters = {
    inherit (barParameters) modules time date;
    inherit (bar.rail) width channel;
    throw = keyword bar.rail.throwMode;
    carry-max = bar.rail.carryMax;
    focus-border = false;
    focus = keyword bar.rail.focus;
    motion = {
      duration-ms = bar.rail.motion.durationMs;
      curve = keyword bar.rail.motion.curve;
    };
    trail = bar.rail.trail && tomoeKnows "cursor-trail";
    theme-bind = binding ["alt" "shift"] "t" "rail-theme" "Next Rail Theme";
    place =
      map (placement: [(keyword placement.frame) (keyword placement.edge)])
      bar.rail.place;
    colors = lib.mapAttrs (_: keyword) {
      ink = "ink";
      rim = "rim";
      tray = "counter";
    };
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
    // {
      colors =
        {
          rail = {
            dark = railColors;
            light = railLightColors;
          };
        }.${
          bar.style
        }
        or {
          dark = cassetteColors;
          light = cassetteColors;
        };
    };

  glassParameters = {
    inherit (config.user.appearance.glass) passes offset noise vibrancy;
  };

  glassAlpha = lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (config.user.appearance.glass.opacity * 255 + 0.5)));

  railLightColors = {
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
      lib.concatStrings [
        "(defparameter +cassette+ ${toLisp cassetteParameters})\n"
        "(defparameter +bolo+ (list :state \"${config.user.runtimeDir}/bolo/state\" :level \"${config.user.runtimeDir}/bolo/level\"))\n"
        "(defparameter +rail+ ${toLisp railParameters})\n"
        source_probe
        (generators.lisp.render (({
            and,
            and-key,
            and-optional,
            append,
            at,
            below,
            blank,
            cassette,
            char,
            char-code,
            clock-text,
            collect,
            concatenate,
            cond,
            constant,
            defun,
            defvar,
            digit-char-p,
            dot,
            double,
            ecase,
            eq,
            equal,
            first,
            for,
            format,
            from,
            function,
            getf,
            if',
            in-package,
            kw,
            lambda,
            length,
            let',
            list,
            loop,
            map,
            max,
            member,
            min,
            nil,
            oddp,
            on,
            or',
            parse-integer,
            plusp,
            probe--gpu-p,
            quote,
            realp,
            remove,
            remove-if,
            repeat,
            return,
            round,
            rows,
            second,
            service-state,
            special,
            state-value,
            str,
            string,
            string-upcase,
            stringp,
            subseq,
            substitute,
            t,
            ui,
            uninterned,
            when,
            ...
          }: ({
            cassette--px',
            cassette-mode,
            cassette--c',
            cassette--text,
            cassette--engraved,
            cassette--ghost,
            cassette--window',
            cassette--zone',
            cassette--ladder,
            cassette--led',
            cassette--gauge,
            cassette--degrees',
            cassette--gib',
            cassette--hot-p',
            cassette--fit',
            cassette--reel',
            cassette--media,
            cassette--counter,
            cassette--module',
            cassette--grille',
            cassette--groove,
            cassette--plate',
            cassette--shadow,
            cassette--height',
            cassette--split',
          }: [
            [in-package (uninterned "tomoe-user")]
            blank
            ({n}: [defun cassette--px' [n] [max 1 [round ["*" n [getf (constant cassette) (kw "scale")]]]]])
            blank
            [defvar (special cassette-mode) (kw "dark")]
            blank
            ({key}: [defun cassette--c' [key] [getf [getf [getf (constant cassette) (kw "colors")] (special cassette-mode)] key]])
            blank
            ({
              text,
              color,
            }:
              rows [
                [defun cassette--text [text color]]
                [[ui (kw "text") (kw "text") text (kw "size") [cassette--px' 11] (kw "line-height") [cassette--px' 11] (kw "color") color (kw "font") [getf (constant cassette) (kw "font")]]]
              ])
            blank
            ({
              text,
              color,
            }:
              rows [
                [defun cassette--engraved [text color]]
                [
                  [
                    ui
                    (kw "stack")
                    (kw "children")
                    (rows [
                      [list [ui (kw "column") (kw "padding") (quote [1 0 0 0]) (kw "children") [list [cassette--text text [cassette--c' (kw "shine")]]]]]
                      [[cassette--text text color]]
                    ])
                  ]
                ]
              ])
            blank
            ({text}: [defun cassette--ghost [text] [map (quote string) ({c}: [lambda [c] [if' [digit-char-p c] (char "8") c]]) text]])
            blank
            ({
              text,
              face,
              rim,
              ghost,
              ink,
              shown,
            }:
              rows [
                [
                  defun
                  cassette--window'
                  (rows [
                    [text and-key [face [cassette--c' (kw "lcd")]] [rim [cassette--c' (kw "rim")]] [ghost [cassette--c' (kw "ghost")]]]
                    (at 11 [[ink [cassette--c' (kw "ink")]] [shown text]])
                  ])
                ]
                (rows [
                  [ui (kw "column") (kw "background") face (kw "border") 1 (kw "border-color") rim]
                  [
                    (kw "children")
                    (rows [
                      [list [ui (kw "rect") (kw "height") 1 (kw "background") rim]]
                      (rows [
                        [ui (kw "row") (kw "height") [cassette--px' 11] (kw "align") (kw "center") (kw "padding") [list 0 [cassette--px' 3] 0 [cassette--px' 3]]]
                        [
                          (kw "children")
                          [
                            list
                            [
                              ui
                              (kw "stack")
                              (kw "children")
                              (rows [
                                [list [cassette--text [cassette--ghost text] ghost]]
                                [[cassette--text shown ink]]
                              ])
                            ]
                          ]
                        ]
                      ])
                    ])
                  ]
                ])
              ])
            blank
            ({x}:
              rows [
                [defun cassette--zone' [x]]
                [[cond [[">" x 0.84] [cassette--c' (kw "red")]] [[">" x 0.6] [cassette--c' (kw "amber")]] [t [cassette--c' (kw "green")]]]]
              ])
            blank
            ({fraction}:
              rows [
                [defun cassette--ladder [fraction]]
                ({
                  count,
                  lit,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[count [getf (constant cassette) (kw "segments")]]]
                        [[lit [round ["*" count [max 0 [min 1 fraction]]]]]]
                      ])
                    ]
                    (rows [
                      [ui (kw "row") (kw "gap") [cassette--px' 1] (kw "align") (kw "center")]
                      [
                        (kw "children")
                        ({i}:
                          rows [
                            [loop for i below count]
                            [
                              collect
                              (rows [
                                [ui (kw "rect") (kw "width") [cassette--px' 4] (kw "height") [cassette--px' 8]]
                                [(kw "background") [if' ["<" i lit] [cassette--zone' ["/" ["1+" i] count]] [cassette--c' (kw "led-off")]]]
                              ])
                            ]
                          ])
                      ]
                    ])
                  ])
              ])
            blank
            ({on'}:
              rows [
                [defun cassette--led' [on']]
                [[ui (kw "rect") (kw "width") [cassette--px' 3] (kw "height") [cassette--px' 3] (kw "background") [if' on' [cassette--c' (kw "orange")] [cassette--c' (kw "led-off")]]]]
              ])
            blank
            ({
              label,
              percent,
              detail,
              hot,
            }:
              rows [
                [defun cassette--gauge [label percent detail and-optional hot]]
                ({percent'}:
                  rows [
                    [let' [[percent' [max 0 [min 100 [round [or' percent 0]]]]]]]
                    (rows [
                      [list [cassette--engraved label [cassette--c' (kw "ink")]]]
                      [[cassette--window' [format nil (str "~3D%") percent']]]
                      [[cassette--ladder ["/" percent' 100]]]
                      [[when detail [cassette--engraved detail [if' hot [cassette--c' (kw "orange")] [cassette--c' (kw "dim")]]]]]
                    ])
                  ])
              ])
            blank
            ({value'}: [defun cassette--degrees' [value'] [if' [realp value'] [format nil (str "~2D°") [max 0 [min 99 [round value']]]] (str "--°")]])
            blank
            ({mib}: [defun cassette--gib' [mib] [if' [realp mib] [format nil (str "~4,1FG") ["/" mib (double 1024)]] (str "--.-G")]])
            blank
            ({value'}: [defun cassette--hot-p' [value'] [and [realp value'] [">=" value' [getf (constant cassette) (kw "hot")]]]])
            blank
            ({
              text,
              width,
            }:
              rows [
                [defun cassette--fit' [text width]]
                ({clean}:
                  rows [
                    [let' [[clean [string-upcase [remove-if ({c}: [lambda [c] [">" [char-code c] 126]]) text]]]]]
                    [[format nil (str "~vA") width [if' [">" [length clean] width] [concatenate (quote string) [subseq clean 0 ["-" width 2]] (str "..")] clean]]]
                  ])
              ])
            blank
            ({amount}:
              rows [
                [defun cassette--reel' [amount]]
                ({
                  box,
                  hub,
                  size,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[box [cassette--px' 12]]]
                        [[hub [cassette--px' 4]]]
                        [[size ["+" hub ["*" 2 [round ["*" ["-" box hub] [max 0 [min 1 amount]]] 2]]]]]
                      ])
                    ]
                    (rows [
                      [ui (kw "stack") (kw "width") box (kw "height") box]
                      [
                        (kw "children")
                        (rows [
                          [
                            list
                            (rows [
                              [ui (kw "row") (kw "width") box (kw "height") box (kw "justify") (kw "center") (kw "align") (kw "center")]
                              [
                                (kw "children")
                                [
                                  list
                                  (rows [
                                    [ui (kw "circular-progress") (kw "size") size (kw "thickness") [max 1 ["/" ["-" size hub] 2]] (kw "value") 1]
                                    [(kw "color") [cassette--c' (kw "tape")] (kw "track") [cassette--c' (kw "tape")]]
                                  ])
                                ]
                              ]
                            ])
                          ]
                          (rows [
                            [ui (kw "row") (kw "width") box (kw "height") box (kw "justify") (kw "center") (kw "align") (kw "center")]
                            [
                              (kw "children")
                              [
                                list
                                (rows [
                                  [ui (kw "circular-progress") (kw "size") hub (kw "thickness") 1 (kw "value") 1]
                                  [(kw "color") [cassette--c' (kw "ink")] (kw "track") [cassette--c' (kw "ink")]]
                                ])
                              ]
                            ]
                          ])
                        ])
                      ]
                    ])
                  ])
              ])
            blank
            ({snapshot}:
              rows [
                [defun cassette--media [snapshot]]
                ({
                  service,
                  status,
                  title,
                  artist,
                  length',
                  position',
                  played,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[service [service-state snapshot (kw "mpris")]]]
                        [[status [getf service (kw "status")]]]
                        [[title [getf service (kw "title")]]]
                        [[artist [getf service (kw "artist")]]]
                        [[length' [getf service (kw "length")]]]
                        [[position' [getf service (kw "position")]]]
                        [[played [if' [and [realp length'] [plusp length'] [realp position']] [max 0 [min 1 ["/" position' length']]] 0]]]
                      ])
                    ]
                    (rows [
                      [when [and [stringp title] [plusp [length title]] [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
                      (rows [
                        [list [cassette--led' [equal status (str "Playing")]]]
                        (rows [
                          [ui (kw "row") (kw "height") [cassette--px' 12] (kw "align") (kw "center") (kw "gap") [cassette--px' 3] (kw "padding") [list 0 [cassette--px' 4] 0 0]]
                          [(kw "background") [cassette--c' (kw "paper")] (kw "border") 1 (kw "border-color") [cassette--c' (kw "rim")]]
                          [
                            (kw "children")
                            (rows [
                              [list [ui (kw "rect") (kw "width") [cassette--px' 2] (kw "height") ["-" [cassette--px' 12] 2] (kw "background") [cassette--c' (kw "orange")]]]
                              [[ui (kw "rect") (kw "width") [cassette--px' 2] (kw "height") ["-" [cassette--px' 12] 2] (kw "background") [cassette--c' (kw "teal")]]]
                              [[cassette--reel' ["-" 1 played]]]
                              (rows [
                                [
                                  cassette--text
                                  (rows [
                                    [
                                      cassette--fit'
                                      (rows [
                                        [if' [and [stringp artist] [plusp [length artist]]]]
                                        [[format nil (str "~A - ~A") artist title]]
                                        title
                                      ])
                                    ]
                                    [[getf (constant cassette) (kw "media-width")]]
                                  ])
                                ]
                                [[cassette--c' (kw "ink")]]
                              ])
                              [[cassette--reel' played]]
                            ])
                          ]
                        ])
                      ])
                    ])
                  ])
              ])
            blank
            (rows [
              [defun cassette--counter []]
              ({time}:
                rows [
                  [let' [[time [clock-text [getf (constant cassette) (kw "time")]]]]]
                  [
                    [
                      list
                      (rows [
                        [cassette--window' time (kw "face") [cassette--c' (kw "counter")] (kw "rim") [cassette--c' (kw "ink")] (kw "ghost") [cassette--c' (kw "counter-ghost")]]
                        (at 23 [(kw "ink") [cassette--c' (kw "amber")]])
                        (at 23 [(kw "shown") [if' [oddp [parse-integer [clock-text (str "%S")]]] [substitute (char "Space") (char ":") time] time]])
                      ])
                    ]
                  ]
                ])
            ])
            blank
            ({
              module,
              state,
              snapshot,
            }:
              rows [
                [defun cassette--module' [module state snapshot]]
                ({
                  cpu,
                  memory,
                  gpu,
                }:
                  rows [
                    [let' [[cpu [getf state (kw "cpu")]] [memory [getf state (kw "memory")]] [gpu [getf state (kw "gpu")]]]]
                    (rows [
                      [ecase module]
                      [[(kw "time") [cassette--counter]]]
                      [[(kw "date") [list [cassette--engraved [string-upcase [clock-text [getf (constant cassette) (kw "date")]]] [cassette--c' (kw "ink")]]]]]
                      [[(kw "media") [cassette--media snapshot]]]
                      [[(kw "cpu") [cassette--gauge (str "CPU") [getf cpu (kw "percent")] [cassette--degrees' [getf cpu (kw "temp")]] [cassette--hot-p' [getf cpu (kw "temp")]]]]]
                      [[(kw "memory") [cassette--gauge (str "MEM") [getf memory (kw "percent")] [cassette--gib' [getf memory (kw "used")]]]]]
                      [
                        [
                          (kw "gpu")
                          (rows [
                            [when [probe--gpu-p gpu]]
                            [[cassette--gauge (str "GPU") [getf gpu (kw "percent")] [cassette--degrees' [getf gpu (kw "temp")]] [cassette--hot-p' [getf gpu (kw "temp")]]]]
                          ])
                        ]
                      ]
                      [
                        [
                          (kw "vram")
                          (rows [
                            [when [probe--gpu-p gpu]]
                            (rows [
                              [cassette--gauge (str "VRAM") [if' [plusp [or' [getf gpu (kw "total")] 0]] [round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]] 0]]
                              [[cassette--gib' [getf gpu (kw "used")]]]
                            ])
                          ])
                        ]
                      ]
                      [
                        [
                          (kw "battery")
                          ({battery}:
                            rows [
                              [let' [[battery [service-state snapshot (kw "battery")]]]]
                              [[cassette--gauge [if' [getf battery (kw "charging")] (str "CHG") (str "BAT")] [getf battery (kw "percent")] nil]]
                            ])
                        ]
                      ]
                      [
                        [
                          (kw "network")
                          ({
                            network,
                            ssid,
                            online,
                          }:
                            rows [
                              ["let*" [[network [service-state snapshot (kw "network")]] [ssid [getf network (kw "ssid")]] [online [getf network (kw "connected")]]]]
                              (rows [
                                [list [cassette--led' online]]
                                (rows [
                                  [cassette--engraved [cassette--fit' [cond [[and online [stringp ssid] [plusp [length ssid]]] ssid] [online (str "online")] [t (str "offline")]] 16]]
                                  [[cassette--c' (kw "ink")]]
                                ])
                              ])
                            ])
                        ]
                      ]
                      [
                        [
                          (kw "frame")
                          ({battery}:
                            rows [
                              [let' [[battery [state-value snapshot (kw "frame-battery")]]]]
                              (rows [
                                [when [getf battery (kw "percent")]]
                                [[cassette--gauge [if' [equal [getf battery (kw "status")] (str "Discharging")] (str "VR") (str "VR+")] [getf battery (kw "percent")] nil]]
                              ])
                            ])
                        ]
                      ]
                    ])
                  ])
              ])
            blank
            (rows [
              [defun cassette--grille' []]
              ({hole}:
                rows [
                  [let' [[hole [cassette--px' 1]]]]
                  (rows [
                    [ui (kw "column") (kw "gap") hole]
                    [
                      (kw "children")
                      (rows [
                        [loop repeat 4]
                        [
                          collect
                          (rows [
                            [ui (kw "row") (kw "gap") hole]
                            [(kw "children") [loop repeat 6 collect [ui (kw "rect") (kw "width") hole (kw "height") hole (kw "background") [cassette--c' (kw "hole")]]]]
                          ])
                        ]
                      ])
                    ]
                  ])
                ])
            ])
            blank
            (rows [
              [defun cassette--groove []]
              [
                [
                  ui
                  (kw "row")
                  (kw "children")
                  (rows [
                    [list [ui (kw "rect") (kw "width") 1 (kw "height") [cassette--px' 10] (kw "background") [cassette--c' (kw "groove")]]]
                    [[ui (kw "rect") (kw "width") 1 (kw "height") [cassette--px' 10] (kw "background") [cassette--c' (kw "shine")]]]
                  ])
                ]
              ]
            ])
            blank
            ({
              items,
              grille,
              edge,
            }:
              rows [
                [defun cassette--plate' [items grille edge]]
                ({
                  parts,
                  body,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [
                          [
                            parts
                            ({
                              item,
                              rest',
                            }:
                              rows [
                                [loop for [item dot rest'] on [remove nil items]]
                                [collect [ui (kw "row") (kw "gap") [cassette--px' 4] (kw "align") (kw "center") (kw "children") [remove nil item]]]
                                [when rest' collect [cassette--groove]]
                              ])
                          ]
                        ]
                        [
                          [
                            body
                            (rows [
                              [ui (kw "row") (kw "height") [cassette--px' 16] (kw "align") (kw "center") (kw "gap") [cassette--px' 6]]
                              [(kw "padding") [list 0 [cassette--px' 6] 0 [cassette--px' 6]]]
                              [
                                (kw "children")
                                (rows [
                                  [append [when [member grille (quote [(kw "start") (kw "both")])] [list [cassette--grille']]]]
                                  parts
                                  [[when [member grille (quote [(kw "end") (kw "both")])] [list [cassette--grille']]]]
                                ])
                              ]
                            ])
                          ]
                        ]
                      ])
                    ]
                    (rows [
                      [when parts]
                      ({plate}:
                        rows [
                          [
                            let'
                            [
                              [
                                plate
                                (rows [
                                  [ui (kw "column") (kw "align") (kw "stretch") (kw "background") [cassette--c' (kw "face")] (kw "border") 1 (kw "border-color") [cassette--c' (kw "ink")]]
                                  [
                                    (kw "children")
                                    (rows [
                                      [list [ui (kw "rect") (kw "height") 1 (kw "background") [cassette--c' (kw "shine")]]]
                                      body
                                      [[ui (kw "rect") (kw "height") 1 (kw "background") [cassette--c' (kw "shade")]]]
                                    ])
                                  ]
                                ])
                              ]
                            ]
                          ]
                          (rows [
                            [if' [eq edge (kw "top")]]
                            (rows [
                              [ui (kw "column") (kw "align") (kw "stretch")]
                              [
                                (kw "children")
                                [
                                  list
                                  plate
                                  (rows [
                                    [ui (kw "row") (kw "height") [cassette--shadow] (kw "padding") [list 0 0 0 [cassette--shadow]]]
                                    [(kw "children") [list [ui (kw "rect") (kw "grow") 1 (kw "height") [cassette--shadow] (kw "background") [cassette--c' (kw "shadow")]]]]
                                  ])
                                ]
                              ]
                            ])
                            plate
                          ])
                        ])
                    ])
                  ])
              ])
            blank
            [defun cassette--shadow [] [cassette--px' 2]]
            blank
            ({edge}: [defun cassette--height' [edge] ["+" [cassette--px' 16] 4 [if' [eq edge (kw "top")] [cassette--shadow] 0]]])
            blank
            (rows [
              [defun cassette--split' []]
              ({pair}:
                rows [
                  [let' [[pair [getf (constant cassette) (kw "center-between")]]]]
                  ({
                    a,
                    b,
                    index,
                  }:
                    rows [
                      [loop for [a b] on [getf (constant cassette) (kw "modules")]]
                      [for index from 1]
                      [when [and b [eq a [first pair]] [eq b [second pair]]] return index]
                    ])
                ])
            ])
          ]))
          generators.lisp))
        (builtins.readFile ./lisp/bolo.lisp)
        (builtins.readFile deck)
      ];
  in {
    panels =
      "(defparameter +bar+ ${toLisp barParameters})\n"
      + (generators.lisp.render (({
          abs,
          and,
          and-optional,
          append,
          assoc,
          at,
          bar,
          below,
          blank,
          by,
          cddr,
          clock-text,
          code-char,
          collect,
          concatenate,
          cond,
          constant,
          context,
          copy-list,
          define-extension,
          defparameter,
          defun,
          double,
          ecase,
          eq,
          eql,
          equal,
          exp,
          find,
          first,
          flet,
          float,
          for,
          format,
          from,
          function,
          getf,
          hex,
          hud,
          hud--c,
          hud--decay,
          hud--dim,
          hud--heat,
          hud--icon,
          hud--mix,
          hud--now,
          hud--off,
          hud--panel,
          hud--text,
          if',
          in',
          in-package,
          interval,
          kw,
          last,
          length,
          let',
          list,
          loop,
          max,
          member,
          min,
          multiple-value-bind,
          nil,
          not,
          nthcdr,
          null',
          on,
          or',
          parse-integer,
          plusp,
          publish-state,
          quote,
          realp,
          reduce,
          remove,
          remove-duplicates,
          repeat,
          return,
          round,
          rows,
          second,
          service-state,
          setf,
          shell-surface,
          sin,
          state-value,
          str,
          string,
          string-upcase,
          stringp,
          subseq,
          t,
          thereis,
          ui,
          uninterned,
          unless,
          values,
          when,
          ...
        }: ({
          bar-probes,
          bar--sample,
          bar--target,
          bar--metric,
          bar--ease,
          bar--moving-p,
          bar--segments,
          bar--spark,
          bar--temp-color,
          bar--gauge,
          bar--degrees,
          bar--gib,
          bar--truncate,
          bar--nonempty,
          bar--media,
          bar--sweep,
          bar--eq,
          bar--clock,
          bar--battery,
          bar--network,
          bar--gpu-p,
          bar--module,
          bar--surfaces,
        }: [
          [in-package (uninterned "tomoe-user")]
          blank
          [defparameter (constant bar-probes) (quote [[(kw "cpu") (kw "cpu")] [(kw "memory") (kw "memory")] [(kw "gpu") (kw "gpu")] [(kw "vram") (kw "gpu")]])]
          blank
          ({
            probe,
            previous,
            system,
          }:
            rows [
              [defun bar--sample [probe previous system]]
              ({sample}:
                rows [
                  [let' [[sample [copy-list previous]]]]
                  (rows [
                    [ecase probe]
                    (rows [
                      (kw "cpu")
                      ({
                        total,
                        idle,
                      }:
                        rows [
                          [let' [[total [getf system (kw "cpu-total")]] [idle [getf system (kw "cpu-idle")]]]]
                          (rows [
                            [when total]
                            ({spent}:
                              rows [
                                [let' [[spent ["-" total [getf sample (kw "total") total]]]]]
                                (rows [
                                  [setf [getf sample (kw "percent")]]
                                  (rows [
                                    [if' [plusp spent]]
                                    [[max 0 [min 100 [round ["*" 100 ["-" spent ["-" idle [getf sample (kw "idle") idle]]]] spent]]]]
                                    [[getf sample (kw "percent") 0]]
                                  ])
                                  [[getf sample (kw "total")] total]
                                  [[getf sample (kw "idle")] idle]
                                  [[getf sample (kw "temp")] [getf system (kw "cpu-temperature")]]
                                ])
                              ])
                          ])
                        ])
                    ])
                    (rows [
                      (kw "memory")
                      ({
                        total,
                        available,
                      }:
                        rows [
                          [let' [[total [getf system (kw "memory-total")]] [available [getf system (kw "memory-available")]]]]
                          (rows [
                            [when [and total [plusp total]]]
                            (rows [
                              [setf [getf sample (kw "percent")] [round ["*" 100 ["-" total available]] total]]
                              [[getf sample (kw "used")] [round ["-" total available] 1024]]
                            ])
                          ])
                        ])
                    ])
                    (rows [
                      (kw "gpu")
                      ({gpu}:
                        rows [
                          [let' [[gpu [first [getf system (kw "gpus")]]]]]
                          (rows [
                            [
                              cond
                              [
                                gpu
                                (rows [
                                  [setf [getf sample (kw "util")] [max 0 [min 100 [getf gpu (kw "busy")]]]]
                                  [[getf sample (kw "used")] [getf gpu (kw "vram-used")]]
                                  [[getf sample (kw "total")] [getf gpu (kw "vram-total")]]
                                  [[getf sample (kw "temp")] [getf gpu (kw "temperature")]]
                                  [[getf sample (kw "failures")] 0]
                                ])
                              ]
                            ]
                            [[system [setf [getf sample (kw "failures")] ["1+" [getf sample (kw "failures") 0]]]]]
                          ])
                        ])
                    ])
                  ])
                  sample
                ])
            ])
          blank
          ({
            module,
            state,
          }:
            rows [
              [defun bar--target [module state]]
              ({gpu}:
                rows [
                  [let' [[gpu [getf state (kw "gpu")]]]]
                  (rows [
                    [ecase module]
                    [[(kw "cpu") [getf [getf state (kw "cpu")] (kw "percent") 0]]]
                    [[(kw "memory") [getf [getf state (kw "memory")] (kw "percent") 0]]]
                    [[(kw "gpu") [getf gpu (kw "util") 0]]]
                    [
                      [
                        (kw "vram")
                        (rows [
                          [if' [plusp [or' [getf gpu (kw "total")] 0]]]
                          [[round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]]]
                          0
                        ])
                      ]
                    ]
                  ])
                ])
            ])
          blank
          ({
            m,
            target,
            push',
          }:
            rows [
              [defun bar--metric [m target push']]
              ({
                m',
                old,
              }:
                rows [
                  [let' [[m' [copy-list m]] [old [getf m (kw "target")]]]]
                  (rows [
                    [when [and old [or' [">=" ["-" target old] 25] [and [">=" target 90] ["<" old 90]]]]]
                    [[setf [getf m' (kw "flash-at")] [hud--now]]]
                  ])
                  (rows [
                    [when push']
                    [[setf [getf m' (kw "history")] [last [append [getf m' (kw "history")] [list target]] [getf (constant bar) (kw "history")]]]]
                  ])
                  [[setf [getf m' (kw "target")] target]]
                  (rows [
                    [when [or' [null' [getf m' (kw "shown")]] ["<" [abs ["-" target [getf m' (kw "shown")]]] 3]]]
                    [[setf [getf m' (kw "shown")] [float target (double 1)]]]
                  ])
                  m'
                ])
            ])
          blank
          ({
            m,
            dt,
          }:
            rows [
              [defun bar--ease [m dt]]
              ({
                m',
                shown,
                target,
                next,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[m' [copy-list m]] [shown [getf m' (kw "shown")]] [target [getf m' (kw "target")]]]
                      [[next ["+" target ["*" ["-" shown target] [exp ["-" ["/" dt [getf (constant bar) (kw "tau")]]]]]]]]
                    ])
                  ]
                  [[setf [getf m' (kw "shown")] [if' ["<" [abs ["-" next target]] 0.3] [float target (double 1)] next]]]
                  m'
                ])
            ])
          blank
          ({m}:
            rows [
              [defun bar--moving-p [m]]
              (rows [
                [or' ["/=" [getf m (kw "shown")] [getf m (kw "target")]]]
                [[plusp [hud--decay [getf m (kw "flash-at")] [getf (constant bar) (kw "flash")]]]]
              ])
            ])
          blank
          ({
            p,
            value',
            accent,
            zones,
          }:
            rows [
              [defun bar--segments [p value' accent and-optional [zones t]]]
              ({
                count,
                filled,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[count [getf (constant bar) (kw "segments")]]]
                      [[filled ["*" count [max 0 [min 1 value']]]]]
                    ])
                  ]
                  (rows [
                    [ui (kw "row") (kw "gap") 1 (kw "align") (kw "center")]
                    [
                      (kw "children")
                      ({
                        i,
                        lit,
                      }:
                        rows [
                          [loop for i below count]
                          [for lit "=" [max 0 [min 1 ["-" filled i]]]]
                          [
                            collect
                            (rows [
                              [ui (kw "rect") (kw "width") 4 (kw "height") 14]
                              [
                                (kw "background")
                                (rows [
                                  [hud--mix [hud--off p]]
                                  [[if' zones [hud--heat ["*" 100 ["/" ["1+" i] count]] accent p] accent]]
                                  lit
                                ])
                              ]
                            ])
                          ]
                        ])
                    ]
                  ])
                ])
            ])
          blank
          ({
            p,
            history,
            accent,
          }:
            rows [
              [defun bar--spark [p history accent]]
              ({
                h,
                count,
                scale,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[h 16] [count [length history]]]
                      [[scale [max 20 [reduce (function max) history (kw "initial-value") 0]]]]
                    ])
                  ]
                  (rows [
                    [ui (kw "row") (kw "gap") 1 (kw "align") (kw "end") (kw "height") h]
                    [
                      (kw "children")
                      (rows [
                        [
                          append
                          (rows [
                            [loop repeat ["-" [getf (constant bar) (kw "history")] count]]
                            [collect [ui (kw "rect") (kw "width") 2 (kw "height") 1 (kw "background") [hud--off p]]]
                          ])
                        ]
                        ({
                          v,
                          i,
                        }:
                          rows [
                            [loop for v in' history]
                            [for i from 1]
                            [
                              collect
                              (rows [
                                [ui (kw "rect") (kw "width") 2 (kw "height") [max 1 [round ["*" h v] scale]]]
                                [
                                  (kw "background")
                                  (rows [
                                    [hud--mix [hud--c p (kw "bg")] [hud--heat v accent p]]
                                    [["+" 0.3 ["*" 0.7 ["/" i count]]]]
                                  ])
                                ]
                              ])
                            ]
                          ])
                      ])
                    ]
                  ])
                ])
            ])
          blank
          ({
            p,
            value',
          }:
            rows [
              [defun bar--temp-color [p value']]
              (rows [
                [cond [[not [realp value']] [hud--dim p]]]
                [[[">=" value' [getf (constant bar) (kw "hot")]] [hud--c p (kw "color1")]]]
                [[[">=" value' ["-" [getf (constant bar) (kw "hot")] 10]] [hud--c p (kw "color3")]]]
                [[t [hud--dim p 0.75]]]
              ])
            ])
          blank
          ({
            p,
            accent,
            label,
            m,
            detail,
            detail-color,
          }:
            rows [
              [defun bar--gauge [p accent label m detail detail-color]]
              ({
                shown,
                color,
                flash,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[shown [getf m (kw "shown") 0]]]
                      [[color [hud--heat [round shown] accent p]]]
                      [[flash [hud--decay [getf m (kw "flash-at")] [getf (constant bar) (kw "flash")]]]]
                    ])
                  ]
                  (rows [
                    [hud--panel p color]
                    (rows [
                      ["list*" [hud--text label 11 [hud--dim p]]]
                      (rows [
                        [ui (kw "row") (kw "align") (kw "end")]
                        [
                          (kw "children")
                          (rows [
                            [list [hud--text [format nil (str "~3D") [round shown]] 16 [hud--mix [hud--c p (kw "fg")] color flash]]]
                            [[hud--text (str "%") 11 [hud--dim p]]]
                          ])
                        ]
                      ])
                      [[bar--segments p ["/" shown 100] accent]]
                      [[bar--spark p [getf m (kw "history")] accent]]
                      [[when detail [list [hud--text detail 12 [or' detail-color [hud--dim p 0.75]]]]]]
                    ])
                    [(kw "flash") flash]
                  ])
                ])
            ])
          blank
          ({value'}: [defun bar--degrees [value'] [when [realp value'] [format nil (str "~D°") [round value']]]])
          blank
          ({mib}: [defun bar--gib [mib] [when [realp mib] [format nil (str "~,1FG") ["/" mib (double 1024)]]]])
          blank
          ({
            text,
            limit,
          }:
            rows [
              [defun bar--truncate [text limit]]
              [[if' ["<=" [length text] limit] text [concatenate (quote string) [subseq text 0 ["1-" limit]] (str "…")]]]
            ])
          blank
          ({value'}: [defun bar--nonempty [value'] [and [stringp value'] [plusp [length value']] value']])
          blank
          ({
            snapshot,
            state,
            now,
          }:
            rows [
              [defun bar--media [snapshot state now]]
              ({
                service,
                status,
                title,
                artist,
                key,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[service [service-state snapshot (kw "mpris")]]]
                      [[status [getf service (kw "status")]]]
                      [[title [bar--nonempty [getf service (kw "title")]]]]
                      [[artist [bar--nonempty [getf service (kw "artist")]]]]
                      [[key [list [getf service (kw "player-name")] title status [getf service (kw "position")]]]]
                    ])
                  ]
                  (rows [
                    [unless [equal key [getf state (kw "media-key")]]]
                    [[setf [getf state (kw "media-key")] key [getf state (kw "media-at")] now]]
                  ])
                  (rows [
                    [
                      values
                      (rows [
                        [when [and title [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
                        ({
                          length',
                          playing,
                          elapsed,
                          position',
                        }:
                          rows [
                            [
                              "let*"
                              (rows [
                                [[length' [or' [getf service (kw "length")] 0]]]
                                [[playing [equal status (str "Playing")]]]
                                [[elapsed [if' playing ["-" now [getf state (kw "media-at") now]] 0]]]
                                [[position' [min length' ["+" [or' [getf service (kw "position")] 0] elapsed]]]]
                              ])
                            ]
                            (rows [
                              [list (kw "playing") playing]
                              [
                                (kw "label")
                                [
                                  string-upcase
                                  (rows [
                                    [bar--truncate [if' artist [format nil (str "~A - ~A") artist title] title]]
                                    [[getf (constant bar) (kw "media-width")]]
                                  ])
                                ]
                              ]
                              [(kw "value") [if' [plusp length'] ["/" position' length'] 0]]
                            ])
                          ])
                      ])
                    ]
                    state
                  ])
                ])
            ])
          blank
          ({
            p,
            color,
            value',
          }:
            rows [
              [defun bar--sweep [p color value']]
              [[ui (kw "progress") (kw "height") 2 (kw "radius") 0 (kw "value") value' (kw "color") color (kw "track") [hud--off p]]]
            ])
          blank
          ({
            color,
            playing,
            now,
          }:
            rows [
              [defun bar--eq [color playing now]]
              (rows [
                [ui (kw "row") (kw "gap") 1 (kw "align") (kw "end") (kw "height") 14]
                [
                  (kw "children")
                  ({i}:
                    rows [
                      [loop for i below 5]
                      [
                        collect
                        (rows [
                          [ui (kw "rect") (kw "width") 2]
                          [
                            (kw "height")
                            (rows [
                              [if' playing]
                              [["+" 2 [round ["*" 12 [abs [sin ["+" ["*" now ["+" 5.3 ["*" 2.1 i]]] ["*" 1.7 i]]]]]]]]
                              2
                            ])
                          ]
                          [(kw "background") color]
                        ])
                      ]
                    ])
                ]
              ])
            ])
          blank
          ({
            p,
            state,
            now,
          }:
            rows [
              [defun bar--clock [p state now]]
              ({
                fg,
                accent,
                sec,
                tick,
                frac,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[fg [hud--c p (kw "fg")]] [accent [hud--c p (kw "accent")]]]
                      [[sec [getf state (kw "sec") 0]]]
                      [[tick [hud--decay [getf state (kw "minute-at")] 700]]]
                      [[frac ["/" ["+" sec [min 1 ["-" now [getf state (kw "sec-at") now]]]] 60]]]
                    ])
                  ]
                  (rows [
                    [hud--panel p accent]
                    (rows [
                      [list [hud--icon (hex 983376) 14 accent]]
                      (rows [
                        [ui (kw "column") (kw "gap") 1 (kw "align") (kw "stretch")]
                        [
                          (kw "children")
                          (rows [
                            [
                              list
                              (rows [
                                [ui (kw "row") (kw "align") (kw "end")]
                                [
                                  (kw "children")
                                  (rows [
                                    [list [hud--text [getf state (kw "minute")] 18 [hud--mix fg accent tick]]]
                                    [[hud--text [format nil (str ":~2,'0D") sec] 12 [hud--dim p]]]
                                  ])
                                ]
                              ])
                            ]
                            [[bar--sweep p accent frac]]
                          ])
                        ]
                      ])
                    ])
                    [(kw "flash") tick]
                  ])
                ])
            ])
          blank
          ({
            p,
            battery,
            label,
          }:
            rows [
              [defun bar--battery [p battery and-optional [label (str "BAT")]]]
              ({
                percent,
                charging,
                color,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[percent [round [getf battery (kw "percent") 0]]]]
                      [[charging [getf battery (kw "charging")]]]
                      [
                        [
                          color
                          (rows [
                            [cond [charging [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                            [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
                          ])
                        ]
                      ]
                    ])
                  ]
                  (rows [
                    [hud--panel p color]
                    (rows [
                      ["list*" [hud--text label 11 [hud--dim p]]]
                      (rows [
                        [ui (kw "row") (kw "align") (kw "end")]
                        [
                          (kw "children")
                          (rows [
                            [list [hud--text [format nil (str "~3D") percent] 16 [hud--c p (kw "fg")]]]
                            [[hud--text (str "%") 11 [hud--dim p]]]
                          ])
                        ]
                      ])
                      [[bar--segments p ["/" percent 100] color nil]]
                      [[when charging [list [hud--icon (hex 988171) 13 color]]]]
                    ])
                  ])
                ])
            ])
          blank
          ({
            p,
            network,
          }:
            rows [
              [defun bar--network [p network]]
              ({
                ssid,
                online,
                label,
                color,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[ssid [getf network (kw "ssid")]]]
                      [[online [getf network (kw "connected")]]]
                      [
                        [
                          label
                          (rows [
                            [cond [[and online [stringp ssid] [plusp [length ssid]]] [string-upcase [remove [code-char 0] ssid]]]]
                            [[online (str "ONLINE")]]
                            [[t (str "OFFLINE")]]
                          ])
                        ]
                      ]
                      [[color [if' online [hud--c p (kw "color6")] [hud--c p (kw "color1")]]]]
                    ])
                  ]
                  [
                    [
                      hud--panel
                      p
                      color
                      (rows [
                        [list [hud--icon [if' online (hex 984489) (hex 984490)] 14 color]]
                        [[hud--text [bar--truncate label 20] 14 [hud--c p (kw "fg")]]]
                      ])
                    ]
                  ]
                ])
            ])
          blank
          ({state}:
            rows [
              [defun bar--gpu-p [state]]
              ({gpu}:
                rows [
                  [let' [[gpu [getf state (kw "gpu")]]]]
                  [[and [getf gpu (kw "util")] ["<" [getf gpu (kw "failures") 0] 3]]]
                ])
            ])
          blank
          ({
            module,
            p,
            state,
            snapshot,
            metrics,
            media,
            now,
          }:
            rows [
              [defun bar--module [module p state snapshot metrics media now]]
              ({
                cpu,
                gpu,
              }:
                rows [
                  [let' [[cpu [getf state (kw "cpu")]] [gpu [getf state (kw "gpu")]]]]
                  (rows [
                    [ecase module]
                    [[(kw "time") [bar--clock p state now]]]
                    [
                      [
                        (kw "date")
                        (rows [
                          [hud--panel p [hud--c p (kw "color4")]]
                          (rows [
                            [list [hud--icon (hex 983277) 14 [hud--c p (kw "color4")]]]
                            [[hud--text [string-upcase [clock-text [getf (constant bar) (kw "date")]]] 14 [hud--c p (kw "fg")]]]
                          ])
                        ])
                      ]
                    ]
                    [[(kw "battery") [bar--battery p [service-state snapshot (kw "battery")]]]]
                    [[(kw "network") [bar--network p [service-state snapshot (kw "network")]]]]
                    [
                      [
                        (kw "frame")
                        ({frame}:
                          rows [
                            [let' [[frame [state-value snapshot (kw "frame-battery")]]]]
                            (rows [
                              [when [getf frame (kw "percent")]]
                              (rows [
                                [
                                  bar--battery
                                  p
                                  (rows [
                                    [list (kw "percent") [getf frame (kw "percent")]]
                                    [(kw "charging") [not [equal [getf frame (kw "status")] (str "Discharging")]]]
                                  ])
                                ]
                                (str "VR")
                              ])
                            ])
                          ])
                      ]
                    ]
                    [
                      [
                        (kw "media")
                        (rows [
                          [when media]
                          ({color}:
                            rows [
                              [let' [[color [hud--c p (kw "color5")]]]]
                              (rows [
                                [hud--panel p color]
                                (rows [
                                  [list [bar--eq color [getf media (kw "playing")] now]]
                                  (rows [
                                    [ui (kw "column") (kw "gap") 3 (kw "align") (kw "stretch")]
                                    [
                                      (kw "children")
                                      (rows [
                                        [list [hud--text [getf media (kw "label")] 13 [hud--c p (kw "fg")]]]
                                        [[bar--sweep p color [getf media (kw "value")]]]
                                      ])
                                    ]
                                  ])
                                ])
                              ])
                            ])
                        ])
                      ]
                    ]
                    [
                      [
                        (kw "cpu")
                        (rows [
                          [bar--gauge p [hud--c p (kw "color4")] (str "CPU") [getf metrics (kw "cpu")]]
                          [[bar--degrees [getf cpu (kw "temp")]] [bar--temp-color p [getf cpu (kw "temp")]]]
                        ])
                      ]
                    ]
                    [
                      [
                        (kw "memory")
                        (rows [
                          [bar--gauge p [hud--c p (kw "color5")] (str "MEM") [getf metrics (kw "memory")]]
                          [[bar--gib [getf [getf state (kw "memory")] (kw "used")]] nil]
                        ])
                      ]
                    ]
                    [
                      [
                        (kw "gpu")
                        (rows [
                          [when [bar--gpu-p state]]
                          (rows [
                            [bar--gauge p [hud--c p (kw "color2")] (str "GPU") [getf metrics (kw "gpu")]]
                            [[bar--degrees [getf gpu (kw "temp")]] [bar--temp-color p [getf gpu (kw "temp")]]]
                          ])
                        ])
                      ]
                    ]
                    [
                      [
                        (kw "vram")
                        (rows [
                          [when [bar--gpu-p state]]
                          [[bar--gauge p [hud--c p (kw "color6")] (str "VRAM") [getf metrics (kw "vram")] [bar--gib [getf gpu (kw "used")]] nil]]
                        ])
                      ]
                    ]
                  ])
                ])
            ])
          blank
          ({
            modules,
            panels,
          }:
            rows [
              [defun bar--surfaces [modules panels]]
              ({
                h,
                gap',
                margin,
                inset,
                pair,
                seam,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[h ["+" [getf (constant hud) (kw "height")] [getf (constant hud) (kw "shadow")]]]]
                      [[gap' [getf (constant bar) (kw "gap")]]]
                      [[margin [getf (constant bar) (kw "margin")]]]
                      [[inset [getf (constant bar) (kw "inset")]]]
                      [[pair [getf (constant bar) (kw "center-between")]]]
                      [
                        [
                          seam
                          ({
                            a,
                            b,
                            index,
                          }:
                            rows [
                              [loop for [a b] on modules]
                              [for index from 1]
                              [when [and b [eq a [first pair]] [eq b [second pair]]] return index]
                            ])
                        ]
                      ]
                    ])
                  ]
                  ({half}:
                    rows [
                      [
                        flet
                        [
                          ({
                            list',
                            justify,
                            padding,
                          }:
                            rows [
                              [half [list' justify padding]]
                              (rows [
                                [ui (kw "row") (kw "width") 0 (kw "grow") 1 (kw "height") h (kw "gap") gap' (kw "justify") justify (kw "padding") padding]
                                [(kw "children") [remove nil list']]
                              ])
                            ])
                        ]
                      ]
                      ({edge}:
                        rows [
                          [loop for edge in' [getf (constant bar) (kw "edges")]]
                          [
                            collect
                            (rows [
                              [shell-surface edge]
                              (rows [
                                [ui (kw "row") (kw "height") h (kw "justify") (kw "center")]
                                [
                                  (kw "children")
                                  (rows [
                                    [if' seam]
                                    (rows [
                                      [list [half [subseq panels 0 seam] (kw "end") [list 0 inset 0 0]]]
                                      [[half [nthcdr seam panels] (kw "start") [list 0 0 0 inset]]]
                                    ])
                                    [[list [ui (kw "row") (kw "height") h (kw "gap") gap' (kw "children") [remove nil panels]]]]
                                  ])
                                ]
                              ])
                              [(kw "anchors") [if' seam [list edge (kw "left") (kw "right")] [list edge]]]
                              [(kw "margin") [if' [eq edge (kw "top")] [list margin 0 0 0] [list 0 0 margin 0]]]
                              [(kw "height") h (kw "layer") (kw "overlay")]
                              [(kw "exclusive-zone") 0]
                              [(kw "background") (str "#00000000") (kw "click-through") t]
                            ])
                          ]
                        ])
                    ])
                ])
            ])
          blank
          ({
            snapshot,
            state,
            event,
          }:
            rows [
              [
                define-extension
                (str "bar")
                (rows [
                  [(kw "reads") [(kw "services") (kw "system") (kw "data")]]
                  [
                    (kw "state")
                    (rows [
                      [list (kw "cpu") nil (kw "memory") nil (kw "gpu") nil (kw "metrics") nil (kw "at") nil]
                      [(kw "sec") nil (kw "sec-at") nil (kw "minute") nil (kw "minute-at") nil]
                    ])
                  ]
                ])
              ]
              [[snapshot state event]]
              ({
                modules,
                probes,
                probe,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[modules [getf (constant bar) (kw "modules")]]]
                      [
                        [
                          probes
                          [
                            remove-duplicates
                            ({
                              module,
                              source,
                            }:
                              rows [
                                [loop for module in' modules]
                                [for source "=" [second [assoc module (constant bar-probes)]]]
                                [when source collect source]
                              ])
                          ]
                        ]
                      ]
                      [[probe [and [eq [getf event (kw "type")] (kw "timer")] [find [getf event (kw "name")] probes]]]]
                    ])
                  ]
                  (rows [
                    [when probe]
                    [[setf [getf state probe] [bar--sample probe [getf state probe] [context snapshot (kw "system")]]]]
                  ])
                  ({
                    p,
                    now,
                    dt,
                    metrics,
                    sec,
                    minute,
                  }:
                    rows [
                      [
                        "let*"
                        (rows [
                          [[p [state-value snapshot (kw "hud-palette")]]]
                          [[now [hud--now]]]
                          [[dt [if' [getf state (kw "at")] ["-" now [getf state (kw "at")]] 0]]]
                          [
                            [
                              metrics
                              ({
                                module,
                                source,
                              }:
                                rows [
                                  [loop for [module source] in' (constant bar-probes)]
                                  [when [member module modules]]
                                  (at 8 [
                                    append
                                    [
                                      list
                                      module
                                      (rows [
                                        [
                                          bar--ease
                                          (rows [
                                            [bar--metric [getf [getf state (kw "metrics")] module]]
                                            [[bar--target module state]]
                                            [[eq source probe]]
                                          ])
                                        ]
                                        dt
                                      ])
                                    ]
                                  ])
                                ])
                            ]
                          ]
                          [[sec [or' [parse-integer [clock-text (str "%S")] (kw "junk-allowed") t] 0]]]
                          [[minute [clock-text [getf (constant bar) (kw "time")]]]]
                        ])
                      ]
                      [[setf [getf state (kw "metrics")] metrics [getf state (kw "at")] now]]
                      (rows [
                        [unless [eql sec [getf state (kw "sec")]]]
                        [[setf [getf state (kw "sec")] sec [getf state (kw "sec-at")] now]]
                      ])
                      (rows [
                        [unless [equal minute [getf state (kw "minute")]]]
                        [[setf [getf state (kw "minute-at")] [when [getf state (kw "minute")] now] [getf state (kw "minute")] minute]]
                      ])
                      ({
                        media,
                        next,
                      }:
                        rows [
                          [multiple-value-bind [media next] [if' [member (kw "media") modules] [bar--media snapshot state now] [values nil state]]]
                          [[setf state next]]
                          ({
                            cpu-temp,
                            gpu-temp,
                            limit,
                            hot,
                            moving,
                            panels,
                          }:
                            rows [
                              [
                                "let*"
                                (rows [
                                  [[cpu-temp [getf [getf state (kw "cpu")] (kw "temp")]]]
                                  [[gpu-temp [getf [getf state (kw "gpu")] (kw "temp")]]]
                                  [[limit [getf (constant bar) (kw "hot")]]]
                                  [[hot [or' [and [realp cpu-temp] [">=" cpu-temp limit]] [and [realp gpu-temp] [">=" gpu-temp limit]]]]]
                                  [[moving ({m}: [loop for [nil m] on metrics by (function cddr) thereis [bar--moving-p m]])]]
                                  [
                                    [
                                      panels
                                      ({module}:
                                        rows [
                                          [loop for module in' modules]
                                          [collect [bar--module module p state snapshot metrics media now]]
                                        ])
                                    ]
                                  ]
                                ])
                              ]
                              (rows [
                                [values state]
                                (rows [
                                  [append [list [interval (kw "clock") [getf (constant bar) (kw "clock-tick")]]]]
                                  ({source}:
                                    rows [
                                      [loop for source in' probes]
                                      [when ["<" [getf [getf state source] (kw "failures") 0] 3]]
                                      (at 8 [collect [interval source [getf [getf (constant bar) (kw "sample")] source]]])
                                    ])
                                  [[when moving [list [interval (kw "fast") [getf (constant bar) (kw "tick")]]]]]
                                  [[list [publish-state (kw "hud-hot") [and hot t]]]]
                                  [[bar--surfaces modules panels]]
                                ])
                                nil
                              ])
                            ])
                        ])
                    ])
                ])
            ])
        ]))
        generators.lisp));
    gap =
      "(defparameter +gap+ ${toLisp gapParameters})\n"
      + source_probe
      + (generators.lisp.render (({
          and,
          and-optional,
          and-rest,
          append,
          at,
          below,
          blank,
          by,
          cddr,
          char-code,
          clock-text,
          collect,
          concatenate,
          cond,
          constant,
          context,
          copy-list,
          define-extension,
          defun,
          dolist,
          double,
          ecase,
          eq,
          equal,
          first,
          flet,
          for,
          format,
          from,
          function,
          gap,
          getf,
          hud--alpha,
          hud--c,
          hud--dim,
          hud--heat,
          hud--mix,
          hud--off,
          if',
          in',
          in-package,
          interval,
          kw,
          lambda,
          length,
          let',
          list,
          loop,
          max,
          member,
          min,
          nil,
          not,
          nthcdr,
          on,
          or',
          plusp,
          probe--gpu-p,
          probe--sample,
          publish-state,
          quote,
          realp,
          remove,
          remove-if,
          return,
          round,
          rows,
          second,
          service-state,
          setf,
          shell-surface,
          sort,
          state-value,
          str,
          string,
          string-upcase,
          stringp,
          subseq,
          t,
          thereis,
          ui,
          uninterned,
          values,
          when,
          ...
        }: ({
          gap--ascii,
          gap--degrees,
          gap--gib,
          gap--fit,
          gap--px,
          gap--text,
          gap--item,
          gap--meter,
          gap--gauge,
          gap--words,
          gap--media,
          gap--battery,
          gap--network,
          gap--frame,
          gap--module,
          gap--line,
        }: [
          [in-package (uninterned "tomoe-user")]
          blank
          ({text}: [defun gap--ascii [text] [remove-if ({c}: [lambda [c] [">" [char-code c] 126]]) text]])
          blank
          ({value'}: [defun gap--degrees [value'] [if' [realp value'] [format nil (str "~2D°") [max 0 [min 99 [round value']]]] (str "--°")]])
          blank
          ({mib}: [defun gap--gib [mib] [if' [realp mib] [format nil (str "~4,1FG") ["/" mib (double 1024)]] (str "--.-G")]])
          blank
          ({
            text,
            width,
          }:
            rows [
              [defun gap--fit [text width]]
              [[format nil (str "~vA") width [if' [">" [length text] width] [concatenate (quote string) [subseq text 0 ["-" width 2]] (str "..")] text]]]
            ])
          blank
          ({n}: [defun gap--px [n] [max 1 [round ["*" n [getf (constant gap) (kw "scale")]]]]])
          blank
          ({
            text,
            color,
          }:
            rows [
              [defun gap--text [text color]]
              [[ui (kw "text") (kw "text") text (kw "size") [gap--px 11] (kw "line-height") [gap--px 11] (kw "color") color (kw "font") [getf (constant gap) (kw "font")]]]
            ])
          blank
          ({
            p,
            children,
          }:
            rows [
              [defun gap--item [p children]]
              [
                [
                  ui
                  (kw "stack")
                  (kw "children")
                  (rows [
                    [
                      list
                      (rows [
                        [ui (kw "column") (kw "align") (kw "stretch")]
                        [
                          (kw "children")
                          (rows [
                            [list [ui (kw "rect") (kw "height") [gap--px 3]]]
                            [[ui (kw "rect") (kw "height") [gap--px 8] (kw "background") [hud--alpha [hud--c p (kw "bg")] (str "e6")]]]
                          ])
                        ]
                      ])
                    ]
                    (rows [
                      [ui (kw "row") (kw "height") [gap--px 11] (kw "align") (kw "end") (kw "gap") [gap--px 4]]
                      [(kw "padding") [list 0 [gap--px 4] 0 [gap--px 4]]]
                      [(kw "children") [remove nil children]]
                    ])
                  ])
                ]
              ]
            ])
          blank
          ({
            p,
            value',
            accent,
            zones,
          }:
            rows [
              [defun gap--meter [p value' accent zones]]
              ({filled}:
                rows [
                  [let' [[filled ["*" 12 [max 0 [min 1 value']]]]]]
                  (rows [
                    [ui (kw "row") (kw "gap") [gap--px 1] (kw "height") [gap--px 8] (kw "align") (kw "end")]
                    [
                      (kw "children")
                      ({i}:
                        rows [
                          [loop for i below 12]
                          [
                            collect
                            (rows [
                              [ui (kw "rect") (kw "width") [gap--px 3] (kw "height") [gap--px 8]]
                              [
                                (kw "background")
                                (rows [
                                  [hud--mix [hud--off p]]
                                  [[if' zones [hud--heat ["*" 100 ["/" ["1+" i] 12]] accent p] accent]]
                                  [[max 0 [min 1 ["-" filled i]]]]
                                ])
                              ]
                            ])
                          ]
                        ])
                    ]
                  ])
                ])
            ])
          blank
          ({
            p,
            label,
            accent,
            percent,
            detail,
            zones,
          }:
            rows [
              [defun gap--gauge [p label accent percent detail and-optional [zones t]]]
              [
                [
                  gap--item
                  p
                  (rows [
                    [list [gap--text label accent]]
                    [[gap--text [format nil (str "~3D%") [max 0 [min 100 percent]]] [hud--c p (kw "fg")]]]
                    [[gap--meter p ["/" percent 100] accent zones]]
                    [[when detail [gap--text detail [hud--dim p 0.75]]]]
                  ])
                ]
              ]
            ])
          blank
          ({
            p,
            parts,
          }:
            rows [
              [defun gap--words [p and-rest parts]]
              [
                [
                  gap--item
                  p
                  ({
                    text,
                    color,
                  }: [loop for [text color] on parts by (function cddr) collect [gap--text text [or' color [hud--c p (kw "fg")]]]])
                ]
              ]
            ])
          blank
          ({
            p,
            snapshot,
          }:
            rows [
              [defun gap--media [p snapshot]]
              ({
                service,
                status,
                title,
                artist,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[service [service-state snapshot (kw "mpris")]]]
                      [[status [getf service (kw "status")]]]
                      [[title [getf service (kw "title")]]]
                      [[artist [getf service (kw "artist")]]]
                    ])
                  ]
                  (rows [
                    [when [and [stringp title] [plusp [length title]] [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
                    (rows [
                      [gap--words p [if' [equal status (str "Playing")] (str ">>") (str "||")] [hud--c p (kw "color5")]]
                      (rows [
                        [
                          gap--fit
                          [
                            gap--ascii
                            [
                              string-upcase
                              (rows [
                                [if' [and [stringp artist] [plusp [length artist]]]]
                                (at 5 [[format nil (str "~A - ~A") artist title]])
                                (at 5 title)
                              ])
                            ]
                          ]
                        ]
                        [[round [getf (constant gap) (kw "media-width")] [getf (constant gap) (kw "scale")]]]
                      ])
                      nil
                    ])
                  ])
                ])
            ])
          blank
          ({
            p,
            snapshot,
          }:
            rows [
              [defun gap--battery [p snapshot]]
              ({
                battery,
                percent,
                color,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[battery [service-state snapshot (kw "battery")]]]
                      [[percent [round [getf battery (kw "percent") 0]]]]
                      [
                        [
                          color
                          (rows [
                            [cond [[getf battery (kw "charging")] [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                            [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
                          ])
                        ]
                      ]
                    ])
                  ]
                  [[gap--gauge p [if' [getf battery (kw "charging")] (str "CHG") (str "BAT")] color percent nil nil]]
                ])
            ])
          blank
          ({
            p,
            snapshot,
          }:
            rows [
              [defun gap--network [p snapshot]]
              ({
                network,
                ssid,
                online,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[network [service-state snapshot (kw "network")]]]
                      [[ssid [getf network (kw "ssid")]]]
                      [[online [getf network (kw "connected")]]]
                    ])
                  ]
                  (rows [
                    [
                      gap--words
                      p
                      (rows [
                        [
                          gap--fit
                          (rows [
                            [cond [[and online [stringp ssid] [plusp [length ssid]]] [gap--ascii [string-upcase ssid]]]]
                            [[online (str "ONLINE")]]
                            [[t (str "OFFLINE")]]
                          ])
                        ]
                        20
                      ])
                    ]
                    [[if' online [hud--c p (kw "color6")] [hud--c p (kw "color1")]]]
                  ])
                ])
            ])
          blank
          ({
            p,
            snapshot,
          }:
            rows [
              [defun gap--frame [p snapshot]]
              ({
                battery,
                percent,
                powered,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[battery [state-value snapshot (kw "frame-battery")]]]
                      [[percent [getf battery (kw "percent")]]]
                      [[powered [not [equal [getf battery (kw "status")] (str "Discharging")]]]]
                    ])
                  ]
                  (rows [
                    [when percent]
                    (rows [
                      [gap--gauge p [if' powered (str "VR+") (str "VR")]]
                      (rows [
                        [cond [powered [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                        [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
                      ])
                      [percent nil nil]
                    ])
                  ])
                ])
            ])
          blank
          ({
            module,
            p,
            state,
            snapshot,
          }:
            rows [
              [defun gap--module [module p state snapshot]]
              ({
                cpu,
                memory,
                gpu,
              }:
                rows [
                  [let' [[cpu [getf state (kw "cpu")]] [memory [getf state (kw "memory")]] [gpu [getf state (kw "gpu")]]]]
                  (rows [
                    [ecase module]
                    [[(kw "time") [gap--words p [clock-text [getf (constant gap) (kw "time")]] nil]]]
                    [[(kw "date") [gap--words p [string-upcase [clock-text [getf (constant gap) (kw "date")]]] nil]]]
                    [[(kw "media") [gap--media p snapshot]]]
                    [[(kw "battery") [gap--battery p snapshot]]]
                    [[(kw "network") [gap--network p snapshot]]]
                    [[(kw "frame") [gap--frame p snapshot]]]
                    [[(kw "cpu") [gap--gauge p (str "CPU") [hud--c p (kw "color4")] [getf cpu (kw "percent") 0] [gap--degrees [getf cpu (kw "temp")]]]]]
                    [[(kw "memory") [gap--gauge p (str "MEM") [hud--c p (kw "color5")] [getf memory (kw "percent") 0] [gap--gib [getf memory (kw "used")]]]]]
                    [
                      [
                        (kw "gpu")
                        (rows [
                          [when [probe--gpu-p gpu]]
                          [[gap--gauge p (str "GPU") [hud--c p (kw "color2")] [getf gpu (kw "percent") 0] [gap--degrees [getf gpu (kw "temp")]]]]
                        ])
                      ]
                    ]
                    [
                      [
                        (kw "vram")
                        (rows [
                          [when [probe--gpu-p gpu]]
                          (rows [
                            [gap--gauge p (str "VRAM") [hud--c p (kw "color6")]]
                            [[if' [plusp [or' [getf gpu (kw "total")] 0]] [round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]] 0]]
                            [[gap--gib [getf gpu (kw "used")]]]
                          ])
                        ])
                      ]
                    ]
                  ])
                ])
            ])
          blank
          ({panels}:
            rows [
              [defun gap--line [panels]]
              ({
                modules,
                pair,
                inset,
                seam,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[modules [getf (constant gap) (kw "modules")]]]
                      [[pair [getf (constant gap) (kw "center-between")]]]
                      [[inset [getf (constant gap) (kw "inset")]]]
                      [
                        [
                          seam
                          ({
                            a,
                            b,
                            index,
                          }:
                            rows [
                              [loop for [a b] on modules]
                              [for index from 1]
                              [when [and b [eq a [first pair]] [eq b [second pair]]] return index]
                            ])
                        ]
                      ]
                    ])
                  ]
                  ({half}:
                    rows [
                      [
                        flet
                        [
                          ({
                            items,
                            justify,
                            padding,
                          }:
                            rows [
                              [half [items justify padding]]
                              (rows [
                                [ui (kw "row") (kw "width") 0 (kw "grow") 1 (kw "height") [gap--px 11] (kw "gap") [gap--px 6] (kw "align") (kw "end") (kw "justify") justify (kw "padding") padding]
                                [(kw "children") [remove nil items]]
                              ])
                            ])
                        ]
                      ]
                      (rows [
                        [ui (kw "row") (kw "height") [gap--px 11] (kw "align") (kw "end") (kw "justify") (kw "center")]
                        [
                          (kw "children")
                          (rows [
                            [if' seam]
                            (rows [
                              [list [half [subseq panels 0 seam] (kw "end") [list 0 inset 0 0]]]
                              [[half [nthcdr seam panels] (kw "start") [list 0 0 0 inset]]]
                            ])
                            [[list [ui (kw "row") (kw "height") [gap--px 11] (kw "gap") [gap--px 6] (kw "align") (kw "end") (kw "children") [remove nil panels]]]]
                          ])
                        ]
                      ])
                    ])
                ])
            ])
          blank
          ({
            snapshot,
            state,
            event,
          }:
            rows [
              [
                define-extension
                (str "bar")
                (rows [
                  [(kw "reads") [(kw "system") (kw "services") (kw "data") (kw "outputs")]]
                  [(kw "state") [list (kw "cpu") nil (kw "memory") nil (kw "gpu") nil]]
                ])
              ]
              [[snapshot state event]]
              (rows [
                [when [and [eq [getf event (kw "type")] (kw "timer")] [eq [getf event (kw "name")] (kw "sample")]]]
                ({system}:
                  rows [
                    [let' [[system [context snapshot (kw "system")]]]]
                    ({probe}:
                      rows [
                        [dolist [probe (quote [(kw "cpu") (kw "memory") (kw "gpu")])]]
                        [[setf [getf state probe] [probe--sample probe [getf state probe] system]]]
                      ])
                  ])
              ])
              ({
                p,
                line,
                focal,
                wide,
                height,
                lift,
                hot,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[p [state-value snapshot (kw "hud-palette")]]]
                      [
                        [
                          line
                          [
                            gap--line
                            ({module}:
                              rows [
                                [loop for module in' [getf (constant gap) (kw "modules")]]
                                [collect [gap--module module p state snapshot]]
                              ])
                          ]
                        ]
                      ]
                      [[focal [state-value snapshot (kw "focal-frame")]]]
                      [[wide [first [sort [copy-list [context snapshot (kw "outputs")]] (function ">") (kw "key") ({o}: [lambda [o] [getf o (kw "width")]])]]]]
                      [[height [gap--px 11]]]
                      [[lift [gap--px 6]]]
                      [
                        [
                          hot
                          ({
                            probe,
                            temp,
                          }:
                            rows [
                              [loop for probe in' (quote [(kw "cpu") (kw "gpu")])]
                              [for temp "=" [getf [getf state probe] (kw "temp")]]
                              [thereis [and [realp temp] [">=" temp [getf (constant gap) (kw "hot")]]]]
                            ])
                        ]
                      ]
                    ])
                  ]
                  (rows [
                    [values state]
                    (rows [
                      [
                        append
                        (rows [
                          [list [interval (kw "sample") [getf (constant gap) (kw "sample")]]]
                          [[publish-state (kw "hud-hot") [and hot t]]]
                          (rows [
                            [publish-state (kw "bar-floor")]
                            (rows [
                              [when [member (kw "bottom") [getf (constant gap) (kw "edges")]]]
                              (rows [
                                [
                                  cond
                                  (rows [
                                    focal
                                    (rows [
                                      [list (kw "output") [getf focal (kw "output")]]
                                      [(kw "y") ["+" [getf focal (kw "top")] [getf focal (kw "height")] ["-" lift] height]]
                                    ])
                                  ])
                                ]
                                [[wide [list (kw "output") [getf wide (kw "name")] (kw "y") [getf wide (kw "height")]]]]
                              ])
                            ])
                          ])
                        ])
                      ]
                      ({edge}:
                        rows [
                          [loop for edge in' [getf (constant gap) (kw "edges")]]
                          [
                            collect
                            (rows [
                              [if' focal]
                              (rows [
                                [shell-surface edge line (kw "output") [getf focal (kw "output")] (kw "anchors") (quote [(kw "top") (kw "left")])]
                                [(kw "width") [getf focal (kw "width")] (kw "height") height]
                                [
                                  (kw "margin")
                                  (rows [
                                    [
                                      list
                                      (rows [
                                        [
                                          "-"
                                          (rows [
                                            [if' [eq edge (kw "top")]]
                                            [[getf focal (kw "top")]]
                                            [["+" [getf focal (kw "top")] [getf focal (kw "height")]]]
                                          ])
                                        ]
                                        lift
                                      ])
                                    ]
                                    [0 0 [getf focal (kw "left")]]
                                  ])
                                ]
                                [(kw "layer") (kw "overlay") (kw "background") (str "#00000000") (kw "click-through") t]
                              ])
                              (rows [
                                [shell-surface edge line (kw "output") [getf wide (kw "name")] (kw "anchors") [list edge (kw "left") (kw "right")]]
                                [(kw "height") height (kw "margin") [if' [eq edge (kw "top")] [list ["-" [gap--px 3]] 0 0 0] 0]]
                                [(kw "layer") (kw "overlay") (kw "background") (str "#00000000") (kw "click-through") t]
                              ])
                            ])
                          ]
                        ])
                    ])
                    nil
                  ])
                ])
            ])
        ]))
        generators.lisp));
    cassette = cassetteLisp ./lisp/plates.lisp;
    rail = tomoeCompatLisp + cassetteLisp ./lisp/rail.lisp + railThemeLisp + screenshotLisp;
  };

  railColors = {
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

  shaderWallpapers = [
    {
      name = "cassette-squares";
      path = "${./shaders/cassette-squares.glsl}";
      mode = "light";
    }
    {
      name = "cassette-led";
      path = "${./shaders/cassette-led.glsl}";
      mode = "light";
    }
    {
      name = "hex-spiral";
      path = "${./shaders/hex-spiral.glsl}";
      mode = "dark";
    }
    {
      name = "dot-corridor";
      path = "${./shaders/dot-corridor.glsl}";
      mode = "dark";
    }
    {
      name = "su-ei";
      path = "${./shaders/su-ei.glsl}";
      mode = "light";
    }
    {
      name = "glass-mound";
      path = "${./shaders/glass-mound.glsl}";
      mode = "light";
    }
    {
      name = "llama-herd";
      path = "${./shaders/llama-herd.glsl}";
      mode = "light";
      family = "llama-herd";
      opaque = true;
    }
    {
      name = "llama-herd-night";
      path = "${./shaders/llama-herd-night.glsl}";
      mode = "dark";
      family = "llama-herd";
      opaque = true;
    }
    {
      name = "liquify";
      path = "${shaderDir}/liquify.glsl";
      mode = "light";
    }
    {
      name = "okazz-spheres";
      path = "${shaderDir}/okazz-spheres.glsl";
      mode = "dark";
    }
    {
      name = "balatro";
      path = "${./shaders/balatro.glsl}";
      mode = "dark";
    }
    {
      name = "xmb";
      path = "${shaderDir}/xmb.glsl";
      mode = "dark";
    }
    {
      name = "aurora";
      path = "${shaderDir}/aurora.glsl";
      mode = "dark";
    }
    {
      name = "stars";
      path = "${shaderDir}/stars.glsl";
      mode = "dark";
    }
    {
      name = "towers";
      path = "${shaderDir}/towers.glsl";
      mode = "dark";
    }
    {
      name = "cubes";
      path = "${shaderDir}/cubes.glsl";
      mode = "dark";
    }
    {
      name = "okazz-glyphs";
      path = "${shaderDir}/okazz-glyphs.glsl";
      mode = "dark";
    }
  ];

  wallpaperNames = map (entry: entry.name) shaderWallpapers;

  wallpaper = name: let
    found = lib.filter (entry: entry.name == name) shaderWallpapers;
  in
    if found == []
    then throw "user.ui.tomoe.wallpapers: no shader wallpaper named ${name}; there is ${lib.concatStringsSep ", " wallpaperNames}"
    else builtins.head found;

  shaderWallpaperParameters = {
    shaders = map (entry: [
      entry.path
      0
      (config.user.theme.apply entry.mode)
      entry.mode
      (entry.family or entry.name)
      (entry.opaque or false)
    ]) (map wallpaper cfg.wallpapers);
    preview = {
      width = 256;
      height = 144;
      gap = 24;
      border = 4;
    };
    bind = binding ["alt" "shift"] "b" "shader-wallpaper-menu" "Choose Wallpaper";
  };

  peekParameters.bind = binding ["alt"] "p" "toggle-peek" "Peek at the Desktop";

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
  config.user.dev.prompts.host = ["`TOMOE_SOCKET`, `WAYLAND_DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` in your environment point at the live tomoe session and its bus. Run private Tomoe instances, test clients and anything that injects input only through tomoe's `tools/isolate` (it refuses while those are set: `env -u DISPLAY -u WAYLAND_DISPLAY -u WAYLAND_SOCKET -u TOMOE_SOCKET tools/isolate DIR COMMAND`); never kernel fake input devices or `DISPLAY=:0`."];

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

    motion = {
      durationMs = lib.mkOption {
        type = lib.types.ints.positive;
        default = 160;
        description = "How long a window takes to glide to a new place: a deck scroll bringing the next card forward, a swap, a move between columns, and the rail's readings sliding across the seam with them.";
      };
      curve = lib.mkOption {
        type = lib.types.enum ["linear" "ease-out-quad" "ease-out-cubic" "ease-out-expo"];
        default = "ease-out-cubic";
        description = "The easing of that glide.";
      };
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

    wallpapers = lib.mkOption {
      type = lib.types.listOf (lib.types.enum wallpaperNames);
      default = wallpaperNames;
      description = "Shader wallpapers in menu order: what the wallpaper menu offers and what a session may pick for the theme's mode. Each one carries the colour scheme it applies when picked by hand, and the shaders that share a family are the light and dark versions of one wallpaper, so a session follows the theme from one to the other.";
    };

    bar = {
      style = lib.mkOption {
        type = lib.types.enum ["panels" "gap" "cassette" "rail"];
        default = "panels";
        description = "panels: framed boxes floating over the screen edges. gap: one line of text inside the 8px window gap, covering nothing. cassette: two putty deck plates hanging from the screen edge either side of the centre, with LCD readouts, LED ladders, a tape counter clock and a J-card for media, in a fixed palette that ignores the colour scheme. rail: the deck's seam filled by the rail, drawn with the frames round its cards in one of bar.rail.themes at a time.";
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

      rail = {
        themes = lib.mkOption {
          type = lib.types.listOf (lib.types.enum railThemeNames);
          default = railThemeNames;
          description = "Rail themes in the order Alt+Shift+T steps through them; a session starts on the first and a config reload keeps the one it is on. Each is the whole look: the rail, the window frames and titles, how focus moves, the gauges and bolo's voice, in a dark and a light palette. ${lib.concatMapStringsSep " " (theme: "${theme.name}: ${theme.description}") railThemes}";
        };
        place = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              frame = lib.mkOption {
                type = lib.types.enum ["focused" "column" "output"];
                default = "column";
                description = "The focused card, the layout's column of cards, or the output.";
              };
              edge = lib.mkOption {
                type = lib.types.enum ["top" "bottom" "left" "right" "seam"];
                default = "seam";
                description = "The edge of that frame the rail stands on. A seam is the layout's own: the deck's between its columns, or the one beside the card a headset's layout centres; the other edges are bars along the frame.";
              };
            };
          });
          default = [
            {
              frame = "column";
              edge = "seam";
            }
          ];
          description = "Where the rail stands, one strip per declaration: the frame it is attached to and that frame's edge. Each strip takes its length from the frame, its thickness from the theme and its scale from the frame's output, so the same theme draws it on the desktop and on a headset. The default is the layout's own seam. A headset's top and bottom bars hugging the focal card are [{frame = \"focused\"; edge = \"top\";} {frame = \"focused\"; edge = \"bottom\";}]; the old full-output bars are [{frame = \"output\"; edge = \"top\";} {frame = \"output\"; edge = \"bottom\";}]. The value is the Lisp config's :PLACE, so extraConfig can replace it (setf (getf +rail+ :place) ...) and a config reload applies it.";
        };
        width = lib.mkOption {
          type = lib.types.ints.positive;
          default = 56;
          description = "Rail body width in physical pixels.";
        };
        channel = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
          description = "Air between a window's border and the rail, part of the track the light falls across.";
        };
        trail = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Draw the pointer's own trail in the active theme's shape and colours: the cells its travel crossed over the last fraction of a second, fading behind it, and nothing at all while it rests. Each theme sets its own cell size, life, tiers, dots or cells and colour from its cast, in dark and light alike. Every lit cell rides one instanced draw: the trail costs the frame about 90 us of its 4.17 ms, and the light theme-modes sit at the budget's edge with it on or off.";
        };
        throwMode = lib.mkOption {
          type = lib.types.enum ["slide" "cut"];
          default = "slide";
          description = "slide: a focus change moves the frame (siphon after a pause, pour on a quick switch), and one across the rail also hops the slab over on two springs. cut: the slab and frame appear on the new card at once.";
        };
        carryMax = lib.mkOption {
          type = lib.types.ints.positive;
          default = 24;
          description = "Most carriages emitted; past this only the cards nearest each column's front carry stubs.";
        };
        motion = {
          durationMs = lib.mkOption {
            type = lib.types.ints.positive;
            default = 300;
            description = "How long a focus change takes to draw, in milliseconds: the old frame draining, the slab hopping across the seam, the new frame filling, the crown landing, the marquee running round a ring. Every theme keeps the choreography it was drawn with and plays it over this time, so a shorter duration compresses a move instead of cutting it off. A switch that lands while a move is still being drawn retargets that move -- it keeps the card the move started from and runs for the quick time, 40% of this -- so switching quickly across several windows shows one move to the newest card, not one transition per window.";
          };
          curve = lib.mkOption {
            type = lib.types.enum ["linear" "ease-out-quad" "ease-out-cubic" "ease-out-expo"];
            default = "ease-out-cubic";
            description = "The shape of a focus change's clock: linear moves at one pace, the ease-out curves put the movement at the front and settle it at the end. thread moves on this clock; morph and glass move on their own springs and take only the duration.";
          };
        };
        focus = lib.mkOption {
          type = lib.types.enum ["hairline" "dim" "recede" "glow"];
          default = "glow";
          description = "What a card without focus keeps round it in thread: hairline is the mock's pair of lines, a dark one and a light one just outside it; dim keeps the dark one at half strength; recede keeps nothing, so the focused card's glass rim is the only frame on the screen; glow keeps nothing and adds a soft halo round the focused card's rim. Recede and glow make focus read from across the room; hairline is the busiest.";
        };
      };
    };
  };

  config.user.files.".config/tomoe/init.lisp".text = lib.concatStringsSep "\n" [
    ''
      (in-package #:tomoe-user)
      (load-policy "desktop" :only '("commands" "drag" "screenshot-theme" "notification-popups" "config-error" "screencast" "screenshot-clipboard"))
      (defun policy-known-settings (plist)
        "PLIST without the settings the running Tomoe does not know: a config is
      loaded by whatever build is running, and a setting that build lacks would refuse
      the session extension and every other setting with it."
        (loop for (key value) on plist by #'cddr
              when (or (not (boundp 'tomoe::+settings+)) (assoc key tomoe::+settings+))
                append (list key value)))
      (defparameter +policy-displays+ ${toLisp (lib.mapAttrsToList (name: settings: [name] ++ lib.concatLists (lib.mapAttrsToList (key: value: [(keyword key) value]) settings)) cfg.displays)})
      (defparameter +policy-settings+ (policy-known-settings ${toLisp ({
          honor-xdg-activation-with-invalid-serial = true;
          focus-follows-mouse = true;
          pointer-follows-focus = true;
          mod = mkLispInline ":super";
        }
        // lib.optionalAttrs (tomoeKnows "cursor-glass") {
          cursor-glass = {
            enabled = true;
            delay-ms = 120;
          };
        }
        // lib.optionalAttrs (tomoeKnows "shadow") {
          shadow = {
            range = 4;
            power = 2;
            color = "#00000040";
          };
        }
        // lib.optionalAttrs (tomoeKnows "pause-readings-when-dark") {
          pause-readings-when-dark = true;
        }
        // lib.optionalAttrs (tomoeKnows "sound-pause-after") {
          sound-pause-after = 5;
        }
        // lib.optionalAttrs config.hardware.nvidia.enable {wait-for-frame-completion = true;}
        // {
          animations =
            {
              window-move = [
                (keyword "ease")
                {
                  duration-ms = cfg.motion.durationMs;
                  curve = keyword cfg.motion.curve;
                }
              ];
            }
            // lib.optionalAttrs (bar.style == "rail") {focus-outline = false;};
        })}))
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
    (generators.lisp.render (({
        and,
        and-optional,
        append,
        apply,
        assoc,
        blank,
        cdr,
        configure-output,
        constant,
        context,
        declare,
        define-extension,
        defun,
        dot,
        equal,
        find,
        first,
        floor,
        focus,
        function,
        getf,
        hide-window,
        ignore,
        in-package,
        kw,
        lambda,
        length,
        let',
        list,
        mapcar,
        max,
        member,
        nil,
        or',
        place,
        policy-displays,
        policy-hidden-window,
        policy-launcher,
        policy-launches,
        policy-settings,
        policy-terminal,
        quote,
        raise-window,
        rows,
        rules-for,
        second,
        settings,
        state-value,
        str,
        stringp,
        t,
        uninterned,
        values,
        when,
        window-properties,
        window-rule,
        ...
      }: ({
        policy--prefix-p,
        policy--launch',
        policy--terminal',
        policy--unmanaged-p',
        policy--area',
        policy--centred',
      }: [
        [in-package (uninterned "tomoe-user")]
        blank
        ({
          prefix,
          text,
        }:
          rows [
            [defun policy--prefix-p [prefix text]]
            (rows [
              [and [stringp text] [">=" [length text] [length prefix]]]
              [["string=" prefix text (kw "end2") [length prefix]]]
            ])
          ])
        blank
        ({command}:
          rows [
            [defun policy--launch' [command]]
            [[second [assoc command (constant policy-launches) (kw "test") (function equal)]]]
          ])
        blank
        ({windows}:
          rows [
            [defun policy--terminal' [windows]]
            (rows [
              [
                getf
                (rows [
                  [find [getf (constant policy-terminal) (kw "app-id")] windows]
                  [(kw "key") ({window}: [lambda [window] [getf window (kw "app-id")]]) (kw "test") (function equal)]
                ])
              ]
              (kw "id")
            ])
          ])
        blank
        ({
          snapshot,
          window,
        }:
          rows [
            [defun policy--unmanaged-p' [snapshot window]]
            ({properties}:
              rows [
                [let' [[properties [rules-for snapshot window]]]]
                [[or' [member [getf window (kw "id")] [state-value snapshot (kw "wm-exclude")]] [cdr [assoc (kw "float") properties]] [cdr [assoc (kw "hidden") properties]]]]
              ])
          ])
        blank
        ({
          snapshot,
          name,
        }:
          rows [
            [defun policy--area' [snapshot and-optional name]]
            ({areas}:
              rows [
                [let' [[areas [context snapshot (kw "workareas")]]]]
                (rows [
                  [or' [find name areas (kw "test") (function equal) (kw "key") ({area}: [lambda [area] [getf area (kw "name")]])]]
                  [[first areas]]
                ])
              ])
          ])
        blank
        ({
          area,
          ratio',
        }:
          rows [
            [defun policy--centred' [area ratio']]
            ({
              width,
              height,
            }:
              rows [
                [
                  let'
                  (rows [
                    [[width [max 1 [floor ["*" [getf area (kw "width")] ratio']]]]]
                    [[height [max 1 [floor ["*" [getf area (kw "height")] ratio']]]]]
                  ])
                ]
                (rows [
                  [list ["+" [getf area (kw "x")] [floor ["-" [getf area (kw "width")] width] 2]]]
                  [["+" [getf area (kw "y")] [floor ["-" [getf area (kw "height")] height] 2]]]
                  [width height]
                ])
              ])
          ])
        blank
        ({
          snapshot,
          state,
          event,
        }:
          rows [
            [define-extension (str "session") [] [snapshot state event]]
            [[declare [ignore snapshot event]]]
            (rows [
              [values state]
              (rows [
                [append [mapcar ({display}: [lambda [display] [apply (function configure-output) display]]) (constant policy-displays)]]
                [[list [apply (function settings) (constant policy-settings)]]]
              ])
              nil
            ])
          ])
        blank
        ({
          snapshot,
          state,
          event,
        }:
          rows [
            [define-extension (str "rules") [] [snapshot state event]]
            [[declare [ignore snapshot event]]]
            (rows [
              [values state]
              (rows [
                [
                  list
                  (rows [
                    [window-rule (kw "launcher")]
                    [
                      (kw "match")
                      ({
                        window,
                        snapshot,
                      }:
                        rows [
                          [lambda [window snapshot]]
                          [[declare [ignore snapshot]]]
                          [[or' [equal [getf window (kw "app-id")] [getf (constant policy-launcher) (kw "app-id")]] [and [equal [getf window (kw "app-id")] [getf (constant policy-terminal) (kw "app-id")]] [equal [getf window (kw "title")] (str "launcher")]]]]
                        ])
                    ]
                    [(kw "properties") (quote [[(kw "float") dot t]]) (kw "reads") (quote [(kw "workareas")])]
                    [
                      (kw "apply")
                      ({
                        window,
                        snapshot,
                        state,
                        event,
                      }:
                        rows [
                          [lambda [window snapshot state event]]
                          [[declare [ignore event]]]
                          ({
                            id,
                            area,
                          }:
                            rows [
                              [
                                let'
                                (rows [
                                  [[id [getf window (kw "id")]]]
                                  [[area [policy--area' snapshot]]]
                                ])
                              ]
                              (rows [
                                [values state]
                                (rows [
                                  [
                                    append
                                    (rows [
                                      [when area]
                                      [
                                        [
                                          list
                                          [
                                            apply
                                            (function place)
                                            id
                                            (rows [
                                              policy--centred'
                                              [area [getf (constant policy-launcher) (kw "ratio")]]
                                            ])
                                          ]
                                        ]
                                      ]
                                    ])
                                  ]
                                  [[list [window-properties id (kw "border") (quote [(kw "focused") (str "#00000000") (kw "unfocused") (str "#00000000")])] [focus id] [raise-window id]]]
                                ])
                                nil
                              ])
                            ])
                        ])
                    ]
                  ])
                ]
                (rows [
                  [window-rule (kw "hidden") (kw "app-id") [getf (constant policy-hidden-window) (kw "app-id")]]
                  [
                    (kw "match")
                    ({
                      window,
                      snapshot,
                    }:
                      rows [
                        [lambda [window snapshot]]
                        [[declare [ignore snapshot]]]
                        (rows [
                          [policy--prefix-p [getf (constant policy-hidden-window) (kw "title-prefix")]]
                          [[getf window (kw "title")]]
                        ])
                      ])
                  ]
                  [(kw "properties") (quote [[(kw "hidden") dot t]])]
                  [
                    (kw "apply")
                    ({
                      window,
                      snapshot,
                      state,
                      event,
                    }:
                      rows [
                        [lambda [window snapshot state event]]
                        [[declare [ignore snapshot event]]]
                        [[values state [list [hide-window [getf window (kw "id")]]] nil]]
                      ])
                  ]
                ])
              ])
              nil
            ])
          ])
      ]))
      generators.lisp))
    (builtins.readFile layout.file)
    userLisp
    "(defparameter +hud+ ${toLisp hudParameters})"
    (generators.lisp.render (({
        and,
        and-key,
        and-optional,
        blank,
        by,
        case,
        code-char,
        collect,
        concatenate,
        cond,
        constant,
        defun,
        double,
        float,
        for,
        format,
        from,
        get-internal-real-time,
        getf,
        hud,
        if',
        in-package,
        internal-time-units-per-second,
        kw,
        length,
        let',
        list,
        loop,
        max,
        min,
        most-positive-fixnum,
        nil,
        or',
        parse-integer,
        plusp,
        quote,
        repeat,
        round,
        rows,
        str,
        string,
        t,
        theme,
        ui,
        uninterned,
        ...
      }: ({
        hud--now',
        hud--since,
        hud--decay',
        hud--c',
        hud--hex2,
        hud--alpha',
        hud--fade,
        hud--mix',
        hud--text',
        hud--icon',
        hud--dim',
        hud--off',
        hud--heat',
        hud--frame,
        hud--panel',
      }: [
        [in-package (uninterned "tomoe-user")]
        blank
        (rows [
          [defun hud--now' []]
          [["/" [float [get-internal-real-time] (double 1)] internal-time-units-per-second]]
        ])
        blank
        ({at'}:
          rows [
            [defun hud--since [at']]
            [[if' at' ["*" 1000 ["-" [hud--now'] at']] most-positive-fixnum]]
          ])
        blank
        ({
          at',
          ms,
        }:
          rows [
            [defun hud--decay' [at' ms]]
            ({elapsed}:
              rows [
                [let' [[elapsed [hud--since at']]]]
                [[if' ["<" elapsed ms] ["-" 1 ["/" elapsed ms]] 0]]
              ])
          ])
        blank
        ({
          p,
          key,
        }:
          rows [
            [defun hud--c' [p key]]
            (rows [
              [or' [getf p key]]
              [
                [
                  theme
                  (rows [
                    [case key]
                    [[(kw "bg") (kw "base")] [[(kw "fg") (kw "color15")] (kw "text")] [(kw "color1") (kw "red")] [(kw "color2") (kw "green")] [(kw "color3") (kw "yellow")]]
                    [[(kw "color4") (kw "blue")] [(kw "color5") (kw "mauve")] [(kw "color6") (kw "sky")] [(kw "color8") (kw "surface2")] [t (kw "accent")]]
                  ])
                ]
              ]
            ])
          ])
        blank
        ({n}: [defun hud--hex2 [n] [format nil (str "~2,'0X") [max 0 [min 255 [round n]]]]])
        blank
        ({
          hex',
          aa,
        }: [defun hud--alpha' [hex' aa] [if' ["=" [length hex'] 7] [concatenate (quote string) hex' aa] hex']])
        blank
        ({
          hex',
          fraction,
        }: [defun hud--fade [hex' fraction] [hud--alpha' hex' [hud--hex2 ["*" 255 fraction]]]])
        blank
        ({
          a,
          b,
          f,
        }:
          rows [
            [defun hud--mix' [a b f]]
            (rows [
              [cond [["<=" f 0] a]]
              (rows [
                [[and ["=" [length a] 7] ["=" [length b] 7]]]
                (rows [
                  [format nil (str "#~{~A~}")]
                  ({i}:
                    rows [
                      [loop for i from 1 by 2 repeat 3]
                      [
                        collect
                        [
                          hud--hex2
                          (rows [
                            ["+" ["*" ["-" 1 f] [parse-integer a (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                            [["*" f [parse-integer b (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                          ])
                        ]
                      ]
                    ])
                ])
              ])
              [[t b]]
            ])
          ])
        blank
        ({
          text,
          size,
          color,
          font,
        }:
          rows [
            [defun hud--text' [text size color and-optional [font [getf (constant hud) (kw "font")]]]]
            [[ui (kw "text") (kw "text") text (kw "size") size (kw "color") color (kw "font") font]]
          ])
        blank
        ({
          code,
          size,
          color,
        }:
          rows [
            [defun hud--icon' [code size color]]
            [[hud--text' [string [code-char code]] size color [getf (constant hud) (kw "icon-font")]]]
          ])
        blank
        ({
          p,
          fraction,
        }: [defun hud--dim' [p and-optional [fraction 0.6]] [hud--fade [hud--c' p (kw "fg")] fraction]])
        blank
        ({p}: [defun hud--off' [p] [hud--mix' [hud--c' p (kw "bg")] [hud--c' p (kw "fg")] 0.14]])
        blank
        ({
          percent,
          accent,
          p,
        }:
          rows [
            [defun hud--heat' [percent accent p]]
            [[cond [[">=" percent 90] [hud--c' p (kw "color1")]] [[">=" percent 70] [hud--c' p (kw "color3")]] [t accent]]]
          ])
        blank
        ({
          p,
          accent,
          flash,
          content,
          height,
        }:
          rows [
            [defun hud--frame [p accent flash content and-key height]]
            ({
              s,
              edge,
              body,
            }:
              rows [
                [
                  "let*"
                  (rows [
                    [[s [getf (constant hud) (kw "shadow")]]]
                    [[edge [hud--mix' accent [hud--c' p (kw "fg")] flash]]]
                    [
                      [
                        body
                        (rows [
                          [ui (kw "row") (kw "height") height (kw "align") (kw "stretch")]
                          [(kw "background") [hud--alpha' [hud--c' p (kw "bg")] (str "eb")]]
                          [(kw "border") 1 (kw "border-color") [hud--alpha' edge [if' [plusp flash] (str "ff") (str "b3")]]]
                          [(kw "children") [list [ui (kw "rect") (kw "width") 3 (kw "background") edge] content]]
                        ])
                      ]
                    ]
                  ])
                ]
                [
                  [
                    ui
                    (kw "stack")
                    (kw "children")
                    (rows [
                      [
                        list
                        (rows [
                          [ui (kw "row") (kw "padding") [list s 0 0 s] (kw "align") (kw "stretch")]
                          [(kw "children") [list [ui (kw "rect") (kw "grow") 1 (kw "background") [hud--mix' [hud--c' p (kw "bg")] edge 0.6]]]]
                        ])
                      ]
                      [[ui (kw "row") (kw "padding") [list 0 s s 0] (kw "children") [list body]]]
                    ])
                  ]
                ]
              ])
          ])
        blank
        ({
          p,
          accent,
          children,
          flash,
        }:
          rows [
            [defun hud--panel' [p accent children and-key [flash 0]]]
            (rows [
              [hud--frame p accent flash [ui (kw "row") (kw "align") (kw "center") (kw "gap") 8 (kw "padding") (quote [0 10 0 8]) (kw "children") children]]
              [(kw "height") [getf (constant hud) (kw "height")]]
            ])
          ])
      ]))
      generators.lisp))
    "(defparameter +hud-theme+ ${toLisp hudThemeParameters})"
    (generators.lisp.render (({
        and,
        append,
        assoc,
        at,
        blank,
        by,
        cdr,
        char,
        char',
        cond,
        cons,
        constant,
        context,
        define-extension,
        defun,
        digit-char-p,
        do,
        dotimes,
        eq,
        eql,
        equal,
        every,
        exec-async,
        first,
        for,
        from,
        function,
        getf,
        hud--c,
        hud--decay,
        hud--mix,
        hud--now,
        hud-theme,
        if',
        in',
        in-package,
        intern,
        interval,
        kw,
        lambda,
        length,
        let',
        list,
        loop,
        member,
        nil,
        not,
        nreverse,
        null',
        or',
        parse-integer,
        plusp,
        position,
        publish-state,
        push,
        quote,
        repeat,
        return,
        reverse,
        rows,
        second,
        setf,
        settings,
        str,
        string-upcase,
        subseq,
        sum,
        t,
        third,
        uninterned,
        unless,
        values,
        watch-file,
        when,
        while,
        with',
        ...
      }: ({
        theme--words,
        theme--hex-p,
        theme--resolve,
        theme--palette,
        theme--mode,
      }: [
        [in-package (uninterned "tomoe-user")]
        blank
        ({line}:
          rows [
            [defun theme--words [line]]
            ({
              words,
              start,
            }:
              rows [
                [let' [[words nil] [start nil]]]
                ({i}:
                  rows [
                    [dotimes [i ["1+" [length line]] [nreverse words]]]
                    (rows [
                      [if' [and ["<" i [length line]] [not [member [char' line i] (quote [(char "Space") (char "Tab") (char ";") (char "Return")])]]]]
                      [[unless start [setf start i]]]
                      [[when start [push [subseq line start i] words] [setf start nil]]]
                    ])
                  ])
              ])
          ])
        blank
        ({value'}:
          rows [
            [defun theme--hex-p [value']]
            (rows [
              [and [member [length value'] (quote [4 7 9])] ["char=" [char' value' 0] (char "#")]]
              [[every ({c}: [lambda [c] [digit-char-p c 16]]) [subseq value' 1]]]
            ])
          ])
        blank
        ({
          name,
          table,
        }:
          rows [
            [defun theme--resolve [name table]]
            ({key}:
              rows [
                [loop with' key "=" name]
                [repeat 8]
                [
                  do
                  ({value'}:
                    rows [
                      [let' [[value' [cdr [assoc key table (kw "test") (function equal)]]]]]
                      (rows [
                        [cond [[null' value'] [return nil]]]
                        [[["char=" [char' value' 0] (char "@")] [setf key [subseq value' 1]]]]
                        [[[theme--hex-p value'] [return value']]]
                        [[t [return nil]]]
                      ])
                    ])
                ]
              ])
          ])
        blank
        ({css}:
          rows [
            [defun theme--palette [css]]
            ({
              table,
              tail,
            }:
              rows [
                [let' [[table nil] [tail css]]]
                ({cut}:
                  rows [
                    [loop while tail]
                    [for cut "=" [position (char "Newline") tail]]
                    [
                      do
                      ({words}:
                        rows [
                          [let' [[words [theme--words [subseq tail 0 [or' cut [length tail]]]]]]]
                          (rows [
                            [when [and ["=" 3 [length words]] [equal [first words] (str "@define-color")]]]
                            [[push [cons [second words] [third words]] table]]
                          ])
                          [[setf tail [and cut [subseq tail ["1+" cut]]]]]
                        ])
                    ]
                  ])
                ({
                  name,
                  value',
                }:
                  rows [
                    [loop for [name] in' [reverse table]]
                    [for value' "=" [theme--resolve name table]]
                    [when value' append [list [intern [string-upcase name] (kw "keyword")] value']]
                  ])
              ])
          ])
        blank
        ({p}:
          rows [
            [defun theme--mode [p]]
            ({bg}:
              rows [
                [let' [[bg [getf p (kw "bg")]]]]
                (rows [
                  [
                    if'
                    (rows [
                      [and bg ["=" [length bg] 7]]
                      (rows [
                        [
                          ">"
                          ({
                            i,
                            weight,
                          }:
                            rows [
                              [loop for i from 1 by 2]
                              [for weight in' (quote [0.2126 0.7152 0.0722])]
                              [sum ["*" weight [parse-integer bg (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                            ])
                        ]
                        127.5
                      ])
                    ])
                  ]
                  (kw "light")
                  (kw "dark")
                ])
              ])
          ])
        blank
        ({
          snapshot,
          state,
          event,
        }:
          rows [
            [define-extension (str "theme") [(kw "reads") [(kw "focus")] (kw "state") [list (kw "palette") nil (kw "watch") nil (kw "focus") nil (kw "focus-at") nil]]]
            [[snapshot state event]]
            ({
              type,
              name,
              focus',
            }:
              rows [
                [let' [[type [getf event (kw "type")]] [name [getf event (kw "name")]] [focus' [context snapshot (kw "focus")]]]]
                (rows [
                  [
                    cond
                    (rows [
                      [[and [eq type (kw "exec")] [member name (quote [(kw "palette") (kw "reread")])] [eql [getf event (kw "code")] 0]]]
                      (rows [
                        [setf [getf state (kw "palette")] [or' [theme--palette [getf event (kw "stdout")]] [getf state (kw "palette")]]]
                        [[getf state (kw "watch")] t]
                      ])
                    ])
                  ]
                  (rows [
                    [[and [eq type (kw "watch")] [eq name (kw "palette")]]]
                    [[setf [getf state (kw "palette")] [or' [theme--palette [getf event (kw "content")]] [getf state (kw "palette")]]]]
                  ])
                ])
                (rows [
                  [unless [equal focus' [getf state (kw "focus")]]]
                  [[setf [getf state (kw "focus")] focus' [getf state (kw "focus-at")] [when focus' [hud--now]]]]
                ])
                ({
                  fixed,
                  p,
                  flash,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[fixed [getf (constant hud-theme) (kw "palette")]]]
                        [[p [or' fixed [getf state (kw "palette")]]]]
                        [[flash [hud--decay [getf state (kw "focus-at")] [getf (constant hud-theme) (kw "focus-flash")]]]]
                      ])
                    ]
                    (rows [
                      [values state]
                      (rows [
                        [
                          append
                          [
                            unless
                            fixed
                            [
                              list
                              (rows [
                                [exec-async [if' [getf state (kw "watch")] (kw "reread") (kw "palette")]]
                                (at 16 [[getf (constant hud-theme) (kw "palette-command")]])
                              ])
                            ]
                          ]
                        ]
                        [[when [getf state (kw "watch")] [list [watch-file (kw "palette") [getf (constant hud-theme) (kw "palette-file")]]]]]
                        [[when [plusp flash] [list [interval (kw "tick") [getf (constant hud-theme) (kw "tick")]]]]]
                        [
                          [
                            when
                            p
                            (rows [
                              [list [publish-state (kw "hud-palette") p]]
                              [[publish-state (kw "theme-mode") [theme--mode p]]]
                              [
                                [
                                  publish-state
                                  (kw "theme")
                                  (rows [
                                    [list (kw "base") [hud--c p (kw "bg")] (kw "text") [hud--c p (kw "fg")]]
                                    [(kw "accent") [hud--c p (kw "accent")] (kw "error") [hud--c p (kw "color1")]]
                                    [(kw "surface1") [hud--c p (kw "color8")]]
                                    [(kw "subtext0") [hud--mix [hud--c p (kw "bg")] [hud--c p (kw "fg")] 0.78]]
                                  ])
                                ]
                              ]
                            ])
                          ]
                        ]
                        [
                          [
                            list
                            [
                              settings
                              (kw "border")
                              (rows [
                                [list (kw "width") [getf (constant hud-theme) (kw "border")] (kw "radius") 0]
                                [(kw "focused") [hud--mix [hud--c p (kw "accent")] [hud--c p (kw "fg")] flash]]
                                [(kw "unfocused") [hud--c p (kw "color8")]]
                              ])
                            ]
                          ]
                        ]
                      ])
                      nil
                    ])
                  ])
              ])
          ])
      ]))
      generators.lisp))
    "(defparameter +glass+ ${toLisp glassParameters})"
    (generators.lisp.render (({
        blank,
        collect,
        cons,
        constant,
        context,
        declare,
        define-extension,
        defun,
        expt,
        for,
        getf,
        glass,
        ignore,
        in',
        in-package,
        kw,
        loop,
        min,
        nil,
        rows,
        settings,
        str,
        t,
        truncate,
        uninterned,
        values,
        window-properties,
        if',
        list,
        ...
      }: ({
        glass--margin,
        glass--known,
      }: [
        [in-package (uninterned "tomoe-user")]
        blank
        ({
          passes,
          offset,
        }:
          rows [
            [defun glass--margin [passes offset]]
            [[min 4096 [truncate ["*" [expt 2 passes] ["+" offset 2]]]]]
          ])
        blank
        ({glass}:
          rows [
            [defun glass--known [glass]]
            [[if' [{symbol = "tomoe-setting-field-known-p";} (kw "blur") (kw "noise")]
                glass
                [list (kw "passes") [getf glass (kw "passes")] (kw "offset") [getf glass (kw "offset")]]]]
          ])
        blank
        ({
          snapshot,
          state,
          event,
        }:
          rows [
            [define-extension (str "glass") [(kw "reads") [(kw "windows")] (kw "state") nil] [snapshot state event]]
            [[declare [ignore event]]]
            (rows [
              [values state]
              (rows [
                [
                  cons
                  [
                    settings
                    (kw "blur")
                    (rows [
                      ["list*" (kw "enabled") t]
                      (kw "anti-artifact-margin")
                      [[glass--margin [getf (constant glass) (kw "passes")] [getf (constant glass) (kw "offset")]]]
                      [[glass--known (constant glass)]]
                    ])
                  ]
                ]
                ({window}:
                  rows [
                    [loop for window in' [context snapshot (kw "windows")]]
                    [collect [window-properties [getf window (kw "id")] (kw "blur") t]]
                  ])
              ])
              nil
            ])
          ])
      ]))
      generators.lisp))
    barLisp.${bar.style}
    "(defparameter +shader-wallpaper+ ${toLisp shaderWallpaperParameters})"
    ''
      (in-package #:tomoe-user)

      (defun shader-wallpaper--menu (shaders chosen outputs)
        (destructuring-bind (&key width height gap border) (getf +shader-wallpaper+ :preview)
          (let ((count (length shaders)))
            (list* (shell-surface :shader-menu (ui :column :on-click :cancel :background "#00000066")
                                  :anchors '(:top :right :bottom :left) :layer :overlay
                                  :background "#00000000" :blur t)
                   (keyboard-grab)
                   (bind-key nil "Left" (list :callback "up")) (bind-key nil "h" (list :callback "up"))
                   (bind-key nil "Right" (list :callback "down")) (bind-key nil "l" (list :callback "down"))
                   (bind-key nil "Return" (list :callback "select"))
                   (bind-key nil "Escape" (list :callback "cancel"))
                   (loop for output in outputs
                         for scale = (getf output :scale-120 120)
                         for output-width = (floor (* (getf output :width) 120) scale)
                         for output-height = (floor (* (getf output :height) 120) scale)
                         for tile-width = (min width (floor (- output-width (* (1+ count) gap)) count))
                         for tile-height = (floor (* height tile-width) width)
                         for left = (floor (- output-width (- (* count (+ tile-width gap)) gap)) 2)
                         for top = (floor (- output-height tile-height) 2)
                         nconc (loop for (path fps) in shaders
                                     for index from 0
                                     collect (shell-surface
                                              (intern (format nil "SHADER-PREVIEW-~A-~D" (getf output :name) index)
                                                      :keyword)
                                              (ui :stack :width tile-width :height tile-height
                                                  :border (if (= index chosen) border 0)
                                                  :border-color (theme :accent)
                                                  :on-click (intern (format nil "SELECT-~D" index) :keyword)
                                                  :on-hover (intern (format nil "HOVER-~D" index) :keyword))
                                              :output (getf output :name) :anchors '(:top :left)
                                              :margin (list top 0 0 (+ left (* index (+ tile-width gap))))
                                              :width tile-width :height tile-height :layer :overlay
                                              :background (list :shader path :fps fps))))))))

      (define-extension "shader-wallpaper" (:reads (:command :ui :outputs :data) :state nil) (snapshot state event)
        (let* ((shaders (getf +shader-wallpaper+ :shaders))
               (count (length shaders))
               (theme (state-value snapshot :theme-mode)))
          (destructuring-bind (&key index menu family mode apply command &allow-other-keys) state
            (when (equal (getf event :owner) "shader-wallpaper")
              (let ((name (if (eq (getf event :type) :command)
                              (getf event :name)
                              (getf event :command))))
                (cond ((equal name "shader-wallpaper-menu")
                       (setf menu (or index 0)))
                      (t
                       (multiple-value-bind (action choice) (and menu (menu-choice event menu count))
                         (case action
                           (:select
                            (setf index choice menu nil
                                  family (fifth (nth choice shaders))
                                  command (third (nth choice shaders))
                                  apply (1+ (or apply 0))))
                           (:cancel (setf menu nil))
                           (:move (setf menu choice))))))))
            (flet ((first-of (name)
                     (position name shaders :test #'equal
                                            :key (lambda (entry) (fourth entry))))
                   (variant (name)
                     (loop for entry in shaders
                           for slot from 0
                           when (and (equal name (fourth entry))
                                     (equal family (fifth entry)))
                             return slot)))
              (let ((now (and theme (string-downcase (symbol-name theme)))))
                (when (and now (not (equal now mode)))
                  (setf mode now)
                  (let ((slot (or (variant now) (first-of now))))
                    (when slot
                      (setf index slot
                            family (fifth (nth slot shaders))))))))
            (when index (setf index (mod index count)))
            (setf menu (and menu (mod menu count)))
            (let* ((slot (or menu index))
                   (shown (and slot (nth slot shaders))))
              (values (list :index index :menu menu :family family :mode mode
                            :apply apply :command command)
                      (append (list (define-command "shader-wallpaper-menu"
                                      :description "Choose the shader wallpaper.")
                                    (apply #'bind-key (getf +shader-wallpaper+ :bind)))
                              (when (and index shown)
                                (list (shell-surface :shader-wallpaper (ui :stack)
                                                     :anchors '(:top :right :bottom :left)
                                                     :layer :background
                                                     :background (append (list :shader (first shown) :fps (second shown))
                                                                         (when (and (sixth shown) (tomoe-shader-option-known-p :opaque))
                                                                           (list :opaque t))))))
                              (when (and command (plusp (or apply 0)))
                                (list (exec-async :theme (format nil "~A # ~D" command apply))))
                              (when menu
                                (shader-wallpaper--menu shaders menu (context snapshot :outputs))))
                      nil)))))
    ''
    "(defparameter +peek+ ${toLisp peekParameters})"
    ''
      (in-package #:tomoe-user)

      (define-extension "peek" (:reads (:command :windows) :state nil) (snapshot hidden event)
        (let ((live (mapcar (lambda (window) (getf window :id)) (context snapshot :windows))))
          (setf hidden (cond ((and (eq (getf event :type) :command)
                                   (equal (getf event :name) "toggle-peek"))
                              (unless hidden live))
                             ((subsetp live hidden) (intersection hidden live))))
          (values hidden
                  (list* (define-command "toggle-peek" :description "Hide every window, or bring them back.")
                         (apply #'bind-key (getf +peek+ :bind))
                         (when hidden (cons (focus nil) (mapcar #'hide-window hidden))))
                  nil)))
    ''
    "(defparameter +sounds+ ${toLisp soundParameters})"
    (generators.lisp.render (({
        constant,
        declare,
        define-extension,
        getf,
        ignore,
        in-package,
        kw,
        list,
        nil,
        sound,
        sounds,
        str,
        uninterned,
        values,
        ...
      }: [
        [in-package (uninterned "tomoe-user")]
        ({
          snapshot,
          state,
          event,
        }: [define-extension (str "sounds") [] [snapshot state event] [declare [ignore snapshot event]] [values state [list [sound (kw "key") [getf (constant sounds) (kw "key")] (kw "gain") [getf (constant sounds) (kw "key-gain")]] [sound (kw "button") [getf (constant sounds) (kw "button")] (kw "gain") [getf (constant sounds) (kw "button-gain")]] [sound (kw "close") [getf (constant sounds) (kw "close")] (kw "gain") [getf (constant sounds) (kw "close-gain")]]] nil]])
      ])
      generators.lisp))
    cfg.extraConfig
  ];
}
