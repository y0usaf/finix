{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name} = {
    directories = [
      ".config/Slack"
      ".config/Slack/IndexedDB"
      ".config/Slack/Local Storage"
      ".config/Slack/Session Storage"
      ".config/Slack/storage"
      ".slack"
    ];
    files = [
      ".config/Slack/Cookies"
      ".config/Slack/Cookies-journal"
      ".config/Slack/Local State"
      ".config/Slack/Network Persistent State"
      ".config/Slack/Preferences"
      ".config/Slack/TransportSecurity"
    ];
  };
  environment.systemPackages = [
    (pkgs.slack.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram $out/bin/slack --add-flags "--disable-remote-fonts"
        '';
    }))
  ];
}
