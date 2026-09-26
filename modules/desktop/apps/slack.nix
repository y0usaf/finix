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
