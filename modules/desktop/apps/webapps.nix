{
  config,
  lib,
  pkgs,
  ...
}: let
  webapp = name: url: categories: comment: {
    generator = lib.generators.toINI {};
    value."Desktop Entry" = {
      Name = name;
      Exec = "${lib.getExe pkgs.chromium} --app=${url} --enable-features=WebContentsForceDark %U";
      Terminal = false;
      Type = "Application";
      Categories = categories;
      Comment = comment;
    };
  };
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/chromium"
  ];
  environment.systemPackages = [pkgs.ungoogled-chromium];
  manzil.users."${config.user.name}".files = {
    ".local/share/applications/gcp-console.desktop" = webapp "GCP Console" "https://console.cloud.google.com" "Development;Network;" "Google Cloud Platform Console";
    ".local/share/applications/google-meet.desktop" = webapp "Google Meet" "https://meet.google.com" "Network;VideoConference;Chat;" "Video conferencing by Google";
    ".local/share/applications/keybard.desktop" = webapp "Keybard" "https://captdeaf.github.io/keybard" "Utility;System;" "Keyboard testing utility";
    ".local/share/applications/linear.desktop" = webapp "Linear" "https://linear.app" "Development;ProjectManagement;" "Linear issue tracking and project management";
  };
}
