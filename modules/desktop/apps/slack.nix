{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.slack = {
    enable = lib.mkEnableOption "Slack package";
  };

  config = lib.mkIf config.user.programs.slack.enable {
    environment.systemPackages = [
      # Slack loads its UI from app.slack.com and ships its own Slack-Lato
      # webfonts via @font-face, which fontconfig cannot override.
      # --disable-remote-fonts makes Blink skip downloadable fonts, so text
      # falls through to the strong sans-serif alias configured in
      # modules/desktop/session/ui/fonts.nix.
      #
      # postFixup (not symlinkJoin) because $out/share/applications/slack.desktop
      # hardcodes Exec=<store>/bin/slack, so an outer join wrapper would be
      # bypassed by desktop launchers.
      (pkgs.slack.overrideAttrs (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram $out/bin/slack --add-flags "--disable-remote-fonts"
          '';
      }))
    ];
  };
}
