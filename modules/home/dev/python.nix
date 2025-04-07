###############################################################################
# Python Development Module
# Provides Python development environment with necessary libraries and tools
# - Python 3 and Python 3.12 interpreters
# - UV package manager for faster dependency resolution
# - System libraries and build tools for Python packages
# - Environment configuration for proper Python operation in Nix
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.cfg.dev.python;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.python = {
    enable = lib.mkEnableOption "Python development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      # Python and UV
      python3 # Basic Python 3 interpreter
      python312 # Python 3.12 specifically
      uv # Fast Python package installer and resolver

      # Build tools
      ninja # Required for building packages like numpy
      meson # Build system used by numpy
      pkg-config # Helps find installed libraries

      # Add CA certificates
      cacert

      # System libraries
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
      xorg.libX11
      xorg.libXext
      xorg.libXrender

      # Add gcc and binutils for compilation
      gcc
      binutils
    ];

    ###########################################################################
    # Environment Variables
    ###########################################################################
    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
      # Add SSL certificates path for Python
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      # Add NIX_LD_LIBRARY_PATH for nix-ld
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.xorg.libX11
        pkgs.xorg.libXext
        pkgs.xorg.libXrender
      ];
      # Set dynamic linker path
      NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}";
      # Add gcc and ld to path
      CC = "${pkgs.gcc}/bin/gcc";
      LD = "${pkgs.binutils}/bin/ld";
    };

    programs.zsh = {
      envExtra = ''
        # Add library paths for Python
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.libGL
          pkgs.glib
          pkgs.xorg.libX11
          pkgs.xorg.libXext
          pkgs.xorg.libXrender
        ]}:$LD_LIBRARY_PATH"

        # Set SSL certificate paths for Python
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

        # Set dynamic linker path
        export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
      '';
    };
  };
}
