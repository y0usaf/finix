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
    # Packages
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
    # Session Variables
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
    # Shell Environment
    ###########################################################################
    files.".zshenv".text = lib.mkAfter ''
      # Python development environment
      export PATH="$PYTHONUSERBASE/bin:$PATH"
      export PYTHONPATH="$PYTHONUSERBASE/lib/python3.12/site-packages:$PYTHONPATH"
    '';

    files.".zshrc".text = lib.mkAfter ''
      # Python development aliases
      alias py="python3"
      alias pip="pip3"
      alias venv="python3 -m venv"
      alias activate="source venv/bin/activate"
      
      # UV aliases
      alias uv-init="uv init"
      alias uv-add="uv add"
      alias uv-run="uv run"
      
      # Virtual environment helpers
      mkvenv() {
        if [[ -z "$1" ]]; then
          python3 -m venv venv
        else
          python3 -m venv "$1"
        fi
      }
      
      workon() {
        if [[ -z "$1" ]]; then
          if [[ -d "venv" ]]; then
            source venv/bin/activate
          else
            echo "No venv directory found"
          fi
        else
          if [[ -d "$VIRTUAL_ENV_HOME/$1" ]]; then
            source "$VIRTUAL_ENV_HOME/$1/bin/activate"
          else
            echo "Virtual environment $1 not found"
          fi
        fi
      }
    '';
  };
}