{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.python;
in {
  options.home.dev.python = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Python development environment";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
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
      file.home = {
        "{{xdg_config_home}}/zsh/.zshenv".text = lib.mkAfter ''
          export PYTHONUSERBASE="{{home}}/.local/share/python"
          export PIP_CACHE_DIR="{{xdg_cache_home}}/pip"
          export VIRTUAL_ENV_HOME="{{home}}/.local/share/venvs"
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
        "{{xdg_config_home}}/zsh/.zshrc".text = lib.mkAfter ''
          alias py="python3"
          alias pip="pip3"
          alias venv="python3 -m venv"
          alias activate="source venv/bin/activate"
          alias uv-init="uv init"
          alias uv-add="uv add"
          alias uv-run="uv run"
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
      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.local/share/python 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/pip 0755 {{user}} {{group}} - -"
        "d {{home}}/.local/share/venvs 0755 {{user}} {{group}} - -"
      ];
    };
  };
}
