{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.gcp-console = {
    enable = lib.mkEnableOption "Google Cloud Platform Console webapp";
  };
  config = lib.mkIf config.user.programs.gcp-console.enable {
    usr = {
      files = {
        ".local/share/applications/gcp-console.desktop" = {
          clobber = true;
          text = ''
            [Desktop Entry]
            Name=GCP Console
            Exec=${lib.getExe pkgs.chromium} --app=https://console.cloud.google.com --enable-features=WebContentsForceDark %U
            Terminal=false
            Type=Application
            Categories=Development;Network;
            Comment=Google Cloud Platform Console
          '';
        };
      };
    };
  };
}
