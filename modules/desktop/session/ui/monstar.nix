{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  userUi = user.ui;
  computedFontSize = toString user.appearance.termFontSize;
  monstarColorsTarget = lib.attrByPath ["user" "appearance" "wallust" "targets" "monstar-colors" "target"] null config;
  # Monstar resolves theme paths literally (no include directive, no ~
  # expansion), so the Wallust target's ~ prefix is expanded to the real
  # home directory here.
  monstarThemePath =
    lib.optionalString (monstarColorsTarget != null)
    "${config.user.homeDirectory}${lib.removePrefix "~" monstarColorsTarget}";
in {
  options.user.ui.monstar = {
    enable = lib.mkEnableOption "monstar terminal emulator";
  };
  config = lib.mkIf userUi.monstar.enable {
    # Main terminal: TERMINAL (modules/core/user/defaults.nix) and the tomoe
    # Mod+t / editor spawns follow user.defaults.terminal.
    user.defaults.terminal = lib.mkDefault "monstar";

    environment.systemPackages = [
      pkgs.monstar
    ];

    manzil.users."${config.user.name}".files.".config/monstar/config" = {
      # Monstar colors are loaded dynamically from the Wallust-generated
      # theme file (theme/modules/wallust/templates/monstar.nix). Monstar has
      # no include directive; instead the absolute theme path below is read
      # directly (monstar(5): "An absolute theme path is read directly").
      # Foot-parity notes:
      #   font = the fontconfig alias in ui/fonts.nix resolves "monospace"
      #     to mainFont, backup, Symbols Nerd Font, emoji — the same chain
      #     foot listed explicitly. Monstar additionally bundles Symbols
      #     Nerd Font internally.
      #   colors-dark alpha = 0.82 with alpha-mode = matching →
      #     background-opacity = 0.82 applies to default-background cells
      #     only, which is foot's "matching" mode (explicit cell colors stay
      #     opaque; monstar's default background-opacity-cells = false).
      #   background-blur = false: foot has no blur.
      #   term = "xterm-256color" has no counterpart: monstar always sets
      #     TERM=monstar and installs its own terminfo entry.
      #   line-height = userUi.foot.lineHeight mirrors foot's setting
      #     (monstar's fork adds foot-style line-height: pt/px cell-height
      #     override, scaled by the output like font-size).
      #   No monstar equivalents exist for foot's bold-text-in-bright,
      #     dpi-aware (monstar is always Wayland fractional-scale aware),
      #     bell.urgent, cursor style/blink (fixed block cursor),
      #     mouse.hide-when-typing / alternate-scroll-mode
      #     (alternate screen wheel → arrows matches foot's yes), and the
      #     clipboard key bindings (copy/paste are fixed at
      #     Ctrl+Shift+C / Ctrl+Shift+V; Ctrl+C stays SIGINT).
      text = ''
        font-size = ${computedFontSize}
        background-opacity = 0.82
        line-height = ${userUi.foot.lineHeight}
        ${lib.optionalString (monstarColorsTarget != null) "theme = ${monstarThemePath}"}
      '';
    };
  };
}
