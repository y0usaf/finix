{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  handyBase = flakeInputs.handy.packages."${pkgs.stdenv.hostPlatform.system}".default;
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

  config = lib.mkIf config.user.programs.handy.enable {
    environment.systemPackages = [
      (handyBase.overrideAttrs (_: {
        preBuild = ''
          cp -r ${pkgs.stdenv.mkDerivation {
            pname = "handy-bun-deps";
            inherit (handyBase) version;
            src = flakeInputs.handy;

            nativeBuildInputs = [
              pkgs.bun
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
            --replace-fail "/usr/bin/env node" "${lib.getExe pkgs.bun}"
          export HOME=$TMPDIR
          bun run build
        '';
      }))
      pkgs.wtype # Ensure wtype is available for Wayland text injection
    ];

    # Send SIGUSR2 to toggle recording
    usr.files.".config/niri/config.kdl".value.binds."${config.user.programs.handy.keybind}" = {
      spawn = ["pkill" "-SIGUSR2" "handy"];
    };
  };
}
