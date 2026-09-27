{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) homeDirectory;
in {
  environment = {
    systemPackages = [
      pkgs.python3
      pkgs.uv
      pkgs.ninja
      pkgs.meson
      pkgs.pkg-config
      pkgs.cacert
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libGL
      pkgs.glib
      pkgs.libx11
      pkgs.libxext
      pkgs.libxrender
      pkgs.gcc
      pkgs.binutils
    ];
    variables = {
      PYTHONSTARTUP = "${homeDirectory}/.config/python/pythonrc";
      PYTHON_HISTORY = "${homeDirectory}/.local/state/python_history";
      PYTHONUSERBASE = "${homeDirectory}/.local/share/python";
      PIP_CACHE_DIR = "${homeDirectory}/.cache/pip";
      VIRTUAL_ENV_HOME = "${homeDirectory}/.local/share/venvs";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.libx11
        pkgs.libxext
        pkgs.libxrender
      ];
      NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
      CC = "${pkgs.gcc}/bin/gcc";
      LD = "${pkgs.binutils}/bin/ld";
    };
  };
  manzil.users."${config.user.name}".files = {
    ".config/python/pythonrc" = {
      text = ''
      '';
    };
  };
  user.shell.rcExtra = lib.mkAfter ''
    PATH="${homeDirectory}/.local/share/python/bin:$PATH"

    alias py="python3"
    alias pip="pip3"
    alias venv="python3 -m venv"
    alias activate="source venv/bin/activate"
    alias uv-init="uv init"
    alias uv-add="uv add"
    alias uv-run="uv run"

    mkvenv() {
      if [ -z "$1" ]; then
        python3 -m venv venv
      else
        python3 -m venv "$1"
      fi
    }

    workon() {
      if [ -z "$1" ]; then
        if [ -d venv ]; then
          . venv/bin/activate
        else
          echo "No venv directory found"
        fi
      elif [ -d "$VIRTUAL_ENV_HOME/$1" ]; then
        . "$VIRTUAL_ENV_HOME/$1/bin/activate"
      else
        echo "Virtual environment $1 not found"
      fi
    }
  '';
}
