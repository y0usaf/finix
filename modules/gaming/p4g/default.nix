{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.gaming.p4g;
  fetch = url: hash: pkgs.fetchurl {inherit url hash;};
  # Full offline pack supplies the curated app config, load order and mod settings.
  cep =
    fetch
    "https://gamebanana.com/dl/1512520"
    "sha256-aiNmBbGa0HXnCiyRFKmALTcBagDUzp+Hqy3d2syGye0=";
  loader =
    fetch
    "https://github.com/Reloaded-Project/Reloaded-II/releases/download/1.30.3/Release.zip"
    "sha256-HdWcLExgnk7Byj7/hR8IOg4V4EbvhNWAgSMPbdehWd4=";
  vcBase = "https://download.visualstudio.microsoft.com/download/pr/bd1c8d9d-ba95-4eee-bc6e-df1fcc876373";
  runtimes = {
    "windowsdesktop-runtime-9.0.20-win-x64.exe" =
      fetch
      "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/9.0.20/windowsdesktop-runtime-9.0.20-win-x64.exe"
      "sha256-VsopJueXw9Ek4Tdm+E1PO3Wg2GsNh344TNpS/dAn5DE=";
    "windowsdesktop-runtime-9.0.20-win-x86.exe" =
      fetch
      "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/9.0.20/windowsdesktop-runtime-9.0.20-win-x86.exe"
      "sha256-ZrpUDgEyQ/8bPsUeDgGwno/cFaqik0xlW37ADA6Sh9o=";
    "vc_redist.x64.exe" =
      fetch
      "${vcBase}/CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B/VC_redist.x64.exe"
      "sha256-zA/w6x3D9RiK5jAPrvMr9b7rpL3W6ORFqRhAcglrcTs=";
    "vc_redist.x86.exe" =
      fetch
      "${vcBase}/0C09F2611660441084CE0DF425C51C11E147E6447963C3690F97E0B25C55ED64/VC_redist.x86.exe"
      "sha256-DAnyYRZgRBCEzg30JcUcEeFH5kR5Y8NpD5fgslxV7WQ=";
  };
  payload =
    pkgs.runCommand "p4g-cep-13.99.4-reloaded-1.30.3" {
      nativeBuildInputs = [pkgs._7zz];
    } ''
      mkdir -p "$out/Reloaded" "$out/Setup"
      7zz x -y ${cep} -oceppack >/dev/null
      cp -r ceppack/P4G-Mods/_Reloaded-II/{Apps,Mods,User} "$out/Reloaded/"
      7zz x -y ${loader} -o"$out/Reloaded" >/dev/null
      7zz x -y "$out/Reloaded/Loader/Asi/UltimateAsiLoader.7z" -o"$out/Asi" >/dev/null
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: src: ''ln -s ${src} "$out/Setup/${name}"'') runtimes)}
    '';
  settings = pkgs.writeText "p4g-settings.json" (builtins.toJSON {
    inherit payload;
    inherit (cfg) stateDirectory gameDirectory prefixDirectory enabledMods;
    steamDirectory = config.user.paths.steam.path;
  });
  package = pkgs.writeShellApplication {
    name = "p4g-setup";
    runtimeInputs = [pkgs.python3 pkgs.protontricks pkgs.coreutils];
    text = ''
      exec python3 ${./setup.py} ${settings} "$@"
    '';
  };
in {
  options.user.gaming.p4g = {
    enable = lib.mkEnableOption "Persona 4 Golden Community Enhancement Pack";
    gameDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.paths.steam.path}/steamapps/common/Persona 4 Golden";
      description = "Existing Steam installation of Persona 4 Golden.";
    };
    prefixDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${builtins.dirOf (builtins.dirOf cfg.gameDirectory)}/compatdata/1113000/pfx";
      description = "P4G's existing Proton prefix, normally in the same Steam library as the game.";
    };
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.homeDirectory}/Games/P4G-CEP";
      description = "Writable mod loader, caches, and setup backups outside Steam and Proton.";
    };
    enabledMods = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Ordered mod IDs, or null to use the CEP author's defaults.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = package;
      description = "Pinned CEP payload and explicit, game-aware setup helper.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
    finit.rlimits.nofile.hard = 524288;
    # Persona Essentials opens thousands of files while merging assets. Finix's
    # login PAM stack reads this file; it has no security.pam.loginLimits option.
    environment.etc."security/limits.conf".text = lib.mkAfter ''
      ${config.user.name} - nofile 524288
    '';
    # Setup is explicit: rebuilding while playing must never mutate a live prefix.
    # The desktop already persists Games, which contains the default stateDirectory.
  };
}
