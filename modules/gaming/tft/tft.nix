# Teamfight Tactics (Android) via Waydroid on NVIDIA.
#
# Boots the Waydroid container + session, then launches TFT directly.
# Persistence: /var/lib/waydroid is in the impermanence allowlist
# (hosts/y0usaf-desktop/impermanence.nix), so the image + userdata +
# installed apps survive reboot. libndk/houdini (ARM translation) are
# one-time setup, already baked into the persisted image — not shipped here.
{
  config,
  lib,
  pkgs,
  ...
}: let
  runtimePkgs = with pkgs; [
    waydroid-nftables
    waydroid-helper
    lxc
    android-tools
    util-linux
  ];
  scripts = ./scripts;

  # One entry point per script, same shape as the old sandbox flake.
  mkEntry = name:
    pkgs.writeShellApplication {
      name = "tft-${name}";
      runtimeInputs = runtimePkgs;
      text = ''
        export WAYDROID="${pkgs.waydroid-nftables}"
        export LXC="${pkgs.lxc}"
        export ANDROID_TOOLS="${pkgs.android-tools}"
        exec bash ${scripts}/${name}.sh "$@"
      '';
    };

  tftPackage = "com.riotgames.league.teamfighttactics";
in {
  options.user.gaming.tft = {
    enable = lib.mkEnableOption "Teamfight Tactics via Waydroid";
  };

  config = lib.mkIf config.user.gaming.tft.enable {
    environment.systemPackages = [
      (mkEntry "launch")
      (mkEntry "init")
      (mkEntry "session")
      (mkEntry "install-tft")
      (mkEntry "tune")
    ];

    # Desktop entry -> tft-launch (on PATH via systemPackages above).
    manzil.users."${config.user.name}".files.".local/share/applications/tft.desktop" = {
      generator = lib.generators.toINI {};
      value."Desktop Entry" = {
        Name = "Teamfight Tactics";
        Comment = "TFT mobile via Waydroid";
        Exec = "tft-launch";
        Terminal = "false";
        Type = "Application";
        Categories = "Game;";
        StartupNotify = "true";
      };
    };
  };
}
