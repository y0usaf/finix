{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.clair-obscur.plugin;
  sources = import ./npins;

  clairobscurfix = pkgs.stdenv.mkDerivation rec {
    pname = "clairobscurfix";
    version = sources.ClairObscurFix.version;

    src = sources.ClairObscurFix;

    nativeBuildInputs = with pkgs; [
      xmake
    ];

    buildPhase = ''
      runHook preBuild
      xmake config --mode=release
      xmake build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      # Copy the built ASI plugin
      cp build/*/release/*.asi $out/bin/ || true
      # Copy configuration file if it exists
      cp *.ini $out/bin/ || true
      runHook postInstall
    '';

    meta = with lib; {
      description = "ClairObscurFix - Performance and visual improvements for Clair Obscur: Expedition 33";
      homepage = "https://codeberg.org/Lyall/ClairObscurFix";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in {
  options.home.gaming.clair-obscur.plugin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ClairObscurFix plugin installation";
    };
  };

  config = lib.mkIf cfg.enable {
    usr.files = {
      # Install the ASI plugin
      ".local/share/Steam/steamapps/common/Clair Obscur Expedition 33/ClairObscurFix.asi" = {
        clobber = true;
        source = "${clairobscurfix}/bin/ClairObscurFix.asi";
      };

      # Install the configuration file
      ".local/share/Steam/steamapps/common/Clair Obscur Expedition 33/ClairObscurFix.ini" = {
        clobber = true;
        generator = lib.generators.toINI {};
        value = {
          Settings = {
            # Remove 30fps cap in cutscenes
            RemoveCutsceneFPSCap = true;
            # Disable game sharpening
            DisableSharpening = true;
            # Skip intro logos
            SkipIntroLogos = true;
            # Enable developer console
            EnableConsole = true;
            # Ultrawide/aspect ratio fixes
            UltrawideSupport = true;
          };
        };
      };
    };
  };
}
