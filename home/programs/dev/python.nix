###############################################################################
# Python Development Module (Maid Version)
# Python development environment with nix-maid configuration
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.dev.python;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.dev.python = {
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
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
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
      # Shell Configuration Files
      ###########################################################################
      file.home = {
        ".zshenv".text = ''
          # Python development environment
          export PYTHONUSERBASE="$HOME/.local/share/python"
          export PIP_CACHE_DIR="{{xdg_cache_home}}/pip"
          export VIRTUAL_ENV_HOME="$HOME/.local/share/venvs"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export NIX_LD_LIBRARY_PATH="${lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.libGL
            pkgs.glib
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXrender
          ]}"
          export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
          export CC="${pkgs.gcc}/bin/gcc"
          export LD="${pkgs.binutils}/bin/ld"
          export PATH="$PYTHONUSERBASE/bin:$PATH"
          export PYTHONPATH="$PYTHONUSERBASE/lib/python3.12/site-packages:$PYTHONPATH"
        '';

        ".zshrc".text = ''
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

      ###########################################################################
      # Directory Setup via tmpfiles
      ###########################################################################
      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.local/share/python 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/pip 0755 {{user}} {{group}} - -"
        "d {{home}}/.local/share/venvs 0755 {{user}} {{group}} - -"
      ];
    };
  };
}
