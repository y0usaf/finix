{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  handyFlake = flakeInputs.handy;
  inherit (pkgs) stdenv bun;
  handyBase = handyFlake.packages."${stdenv.hostPlatform.system}".default;
  handyCfg = config.user.programs.handy;
  # Temporary local fix until cjpais/Handy updates its stale bun deps hash.
in {
  options.user.programs.handy = {
    enable = lib.mkEnableOption "Handy speech-to-text";
    keybind = lib.mkOption {
      type = lib.types.str;
      default = "Alt+V";
      description = "Niri keybind to toggle Handy recording";
    };
  };

  config = lib.mkIf handyCfg.enable {
    environment.systemPackages = [
      (handyBase.overrideAttrs (_: {
        preBuild = ''
          cp -r ${stdenv.mkDerivation {
            pname = "handy-bun-deps";
            inherit (handyBase) version;
            src = handyFlake;

            nativeBuildInputs = [
              bun
              pkgs.cacert
            ];

            dontFixup = true;

            buildPhase = ''
              export HOME=$TMPDIR
              bun install --frozen-lockfile --no-progress
            '';

            installPhase = ''
              mkdir -p $out
              cp -r node_modules $out/
            '';

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = "sha256-+hUANv0w3qnK5d2+4JW3XMazLRDhWCbOxUXQyTGta/0=";
          }}/node_modules node_modules
          chmod -R +w node_modules
          substituteInPlace node_modules/.bin/{tsc,vite} \
            --replace-fail "/usr/bin/env node" "${lib.getExe bun}"
          export HOME=$TMPDIR
          bun run build
        '';
      }))
      pkgs.wtype # Ensure wtype is available for Wayland text injection
    ];

    # Send SIGUSR2 to toggle recording
    bayt.users."${config.user.name}".files.".config/niri/config.kdl".value.binds."${handyCfg.keybind}" = {
      spawn = ["pkill" "-SIGUSR2" "handy"];
    };
  };
}
