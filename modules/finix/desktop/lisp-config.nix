{
  config,
  lib,
  ...
}: let
  inherit (config.lib.generators) mkLispInline toLisp;
  inherit (config.user) defaults;

  # Each row is the argument list for bind-key. Keywords are trusted Lisp
  # expressions; key names and launch arguments remain ordinary Nix strings.
  binding = modifiers: key: command: [(map mkLispInline modifiers) key (mkLispInline command)];

  displays = lib.mapAttrsToList (name: settings: [name settings]) {
    "DP-4".mode = [5120 1440];
    "HDMI-A-2" = {
      mode = [1920 1080 60];
      position = [5120 0];
    };
  };

  deckBindings = [
    (binding [":alt"] "h" ":focus-left")
    (binding [":alt"] "l" ":focus-right")
    (binding [":alt"] "j" ":scroll-down")
    (binding [":alt"] "k" ":scroll-up")
    (binding [":alt" ":shift"] "h" ":swap-columns")
    (binding [":alt" ":shift"] "l" ":swap-columns")
    (binding [":alt" ":shift"] "j" ":move-down")
    (binding [":alt" ":shift"] "k" ":move-up")
    (binding [":alt"] "bracketleft" ":to-left")
    (binding [":alt"] "bracketright" ":to-right")
    (binding [":alt"] "o" ":grid")
    (binding [":alt"] "r" ":ratio")
    (binding [":alt"] "f" ":fullscreen")
    (binding [":super"] "space" ":floating")
    # The deck owns focus, including the shipped focus unit's Super+Tab.
    (binding [":super"] "Tab" ":next")
    (binding [":super" ":shift"] "Tab" ":previous")
  ];

  userBindings = [
    (binding [":alt"] "1" ":cursor")
    (binding [":alt"] "2" ":browser")
    (binding [":alt"] "3" ":discord")
    (binding [":alt"] "4" ":steam")
    (binding [":alt"] "5" ":obs")
    # The daemon owns push-to-talk state; the key only runs `baat toggle`.
    (binding [":alt"] "space" ":ptt")
    (binding [":alt"] "t" ":terminal")
    (binding [":super"] "r" ":launcher")
    (binding [":alt"] "e" ":files")
    (binding [":super" ":shift"] "o" ":editor")
    (binding [":alt"] "q" ":close")
    (binding [":alt" ":shift"] "e" ":quit")
    (binding [":alt"] "g" ":screenshot")
    (binding [":alt" ":shift"] "g" ":screenshot-screen")
    (binding [":alt" ":shift"] "c" ":wallpaper")
    (binding [] "XF86AudioRaiseVolume" ":volume-up")
    (binding [] "XF86AudioLowerVolume" ":volume-down")
    (binding [] "XF86AudioMute" ":volume-mute")
    (binding [] "XF86AudioMicMute" ":mic-mute")
    (binding [] "XF86AudioPlay" ":play-pause")
    (binding [] "XF86AudioNext" ":track-next")
    (binding [] "XF86AudioPrev" ":track-prev")
    (binding [] "XF86MonBrightnessUp" ":brightness-up")
    (binding [] "XF86MonBrightnessDown" ":brightness-down")
  ];

  # String-keyed rows preserve command names; an attrset would turn them into
  # keyword symbols. Lisp calls the fixed launch API with each argv list.
  launches = lib.mapAttrsToList (command: argv: [command argv]) {
    cursor = [defaults.ide];
    browser = [defaults.browser];
    discord = [defaults.discord];
    steam = ["steam"];
    obs = ["obs"];
    ptt = ["baat" "toggle"];
    terminal = [defaults.terminal];
    # user.defaults.launcher is a shell command, including tilde expansion.
    launcher = ["sh" "-c" defaults.launcher];
    files = [defaults.fileManager];
    editor = [defaults.terminal "-e" defaults.editor];
    screenshot = ["sh" "-c" ''grim -g "$(slurp)" - | wl-copy''];
    screenshot-screen = ["sh" "-c" "grim - | wl-copy"];
    wallpaper = [
      "sh"
      "-c"
      ''killall swaybg; swaybg -i "$(find ${lib.escapeShellArg config.user.paths.wallpapers.static.path} -type f | shuf -n 1)" -m fill &''
    ];
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

  deckText = ''
    ;; Generated values from modules/finix/desktop/lisp-config.nix.
    (in-package #:tomoe-user)
    (defparameter +deck-gaps+ ${toLisp 8})
    ;; Keep exact ratios: two 16:9 columns, then 21:9 / 11:9 and its mirror.
    (defparameter +deck-ratios+ ${toLisp (map mkLispInline ["1/2" "21/32" "11/32"])})
    (defparameter +deck-float-numerator+ ${toLisp (mkLispInline "3/5")})
    (defparameter +deck-bindings+ ${toLisp deckBindings})

    ${builtins.readFile ./deck.lisp}
  '';

  # The compositor watches init.lisp, not the deck it loads. Include the
  # generated values in this hash so Nix-only deck changes trigger reloads.
  initText = ''
    ;; Generated values from modules/finix/desktop/lisp-config.nix.
    ;; Deck fingerprint: ${builtins.hashString "sha256" deckText}
    (in-package #:tomoe-user)
    (defparameter +policy-displays+ ${toLisp displays})
    (defparameter +policy-deck-path+ ${toLisp ".config/tomoe/deck.lisp"})
    (defparameter +policy-floating-ratio+ ${toLisp (mkLispInline "3/5")})
    (defparameter +policy-floating-binding+ ${toLisp (binding [":super"] "space" ":toggle")})
    (defparameter +policy-launcher+ ${toLisp {
      app-id = "launcher";
      ratio = mkLispInline "1/3";
    }})
    (defparameter +policy-hidden-window+ ${toLisp {
      app-id = "steam_proton";
      title-prefix = "Lovely";
    }})
    (defparameter +policy-bindings+ ${toLisp userBindings})
    (defparameter +policy-launches+ ${toLisp launches})

    ${builtins.readFile ./tomoe-policy.lisp}
  '';
in {
  options.user.ui.tomoe.lisp = {
    initText = lib.mkOption {
      type = lib.types.lines;
      internal = true;
      readOnly = true;
      description = "Rendered Common Lisp session policy, including serialized Nix values.";
    };
    deckText = lib.mkOption {
      type = lib.types.lines;
      internal = true;
      readOnly = true;
      description = "Rendered Common Lisp deck layout, including serialized Nix values.";
    };
  };

  config.user.ui.tomoe.lisp = {inherit initText deckText;};
}
