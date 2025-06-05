###############################################################################
# Python Development Module (Hjem version)
# Migrated from Home Manager with minimal changes
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.python;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.python = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Python development environment";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages (same as before, just different attribute)
    ###########################################################################
    packages = with pkgs; [
      python3
      python312
      uv
      ninja
      meson
      pkg-config
      cacert
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      gcc
      binutils
    ];

    ###########################################################################
    # Session Variables (minimal change: home.sessionVariables → environment.sessionVariables)
    ###########################################################################
    environment.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.xorg.libX11
        pkgs.xorg.libXext
        pkgs.xorg.libXrender
      ];
      NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}";
      CC = "${pkgs.gcc}/bin/gcc";
      LD = "${pkgs.binutils}/bin/ld";
    };

    ###########################################################################
    # Shell Environment - TODO: Migrate to file registry
    ###########################################################################
    # cfg.hjome.shell.zsh.envExtra = lib.mkAfter ''...''; # Old API - needs migration
    # 
    # New file registry approach:
    # fileRegistry.content.zshenv.python-env = ''...'';
    
    # Disabled until migration is complete
  };
}