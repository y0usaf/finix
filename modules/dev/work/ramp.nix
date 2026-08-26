{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.work.ramp;
  version = "0.2.27";

  # Release assets are PyInstaller onedir tarballs: main.dist/ carries a
  # bundled CPython 3.12 plus every non-glibc shared object except libz
  # (needed by CPython's zlib.so). The launcher keeps rpath $ORIGIN, so on
  # NixOS only the ELF interpreter and libz are missing — autoPatchelfHook
  # fixes both without touching the payload.
  assets = {
    aarch64-darwin = {
      tarball = "ramp-darwin-arm64.tar.gz";
      hash = "sha256-WZUUY8F+Haza9LlvLkMkEP4ti4PAPamLXy9dTnnjZtM=";
    };
    x86_64-darwin = {
      tarball = "ramp-darwin-amd64.tar.gz";
      hash = "sha256-0kaAGVyMxW60Xv4DENOeAh8j1K9cDrYLCkRl9w9stVs=";
    };
    aarch64-linux = {
      tarball = "ramp-linux-arm64.tar.gz";
      hash = "sha256-T5HOZnJKA5tcS6nzE1vUdaZcHdZKxkHTmtt2XnJhd0o=";
    };
    x86_64-linux = {
      tarball = "ramp-linux-amd64.tar.gz";
      hash = "sha256-xccIbLXdDAPmWFRzD/fGC4Co89ivgo6891/Q8ZG5J1c=";
    };
  };
  asset =
    assets."${pkgs.stdenv.hostPlatform.system}"
    or (throw "ramp: unsupported system '${pkgs.stdenv.hostPlatform.system}'");
  # Inner launcher is named after the tarball minus .tar.gz.
  binName = builtins.replaceStrings [".tar.gz"] [""] asset.tarball;
in {
  options.user.dev.work.ramp = {
    enable = lib.mkEnableOption "Ramp CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "ramp";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/ramp-public/ramp-cli/releases/download/v${version}/${asset.tarball}";
          inherit (asset) hash;
        };

        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [pkgs.zlib];

        # Stripping the PyInstaller bootloader/bundled objects buys nothing.
        dontStrip = true;
        installPhase = ''
          runHook preInstall
          # unpackPhase chdirs into the tarball's single root dir main.dist.
          mkdir -p $out/share/ramp $out/bin
          cp -r . $out/share/ramp/main.dist
          ln -s $out/share/ramp/main.dist/${binName} $out/bin/ramp
          runHook postInstall
        '';

        meta = {
          description = "CLI for the Ramp spend management platform";
          homepage = "https://github.com/ramp-public/ramp-cli";
          license = lib.licenses.mit;
          mainProgram = "ramp";
          platforms = [
            "aarch64-darwin"
            "x86_64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ];
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      };
      description = "Ramp CLI package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.libsecret # keyring-backed auth token storage
    ];
  };
}
