{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) homeDirectory;
  inherit (pkgs) cacert gcc binutils;
  inherit (pkgs.stdenv) cc;
  inherit (cc.bintools) dynamicLinker;
  caCert = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  ccLib = cc.cc.lib;
  userName = config.user.name;
  ldLibPath = lib.makeLibraryPath [
    ccLib
    pkgs.zlib
    pkgs.libGL
    pkgs.glib
    pkgs.libx11
    pkgs.libxext
    pkgs.libxrender
  ];
  pythonUserBase = "${homeDirectory}/.local/share/python";
in {
  options.user.dev.python = {
    enable = lib.mkEnableOption "Python development environment";
  };
  config = lib.mkIf config.user.dev.python.enable {
    environment = {
      systemPackages = [
        pkgs.python3
        pkgs.uv
        pkgs.ninja
        pkgs.meson
        pkgs.pkg-config
        cacert
        ccLib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.libx11
        pkgs.libxext
        pkgs.libxrender
        gcc
        binutils
      ];
      variables = {
        PYTHONSTARTUP = "${homeDirectory}/.config/python/pythonrc";
        PYTHON_HISTORY = "${homeDirectory}/.local/state/python_history";
        PYTHONUSERBASE = pythonUserBase;
        PIP_CACHE_DIR = "${homeDirectory}/.cache/pip";
        VIRTUAL_ENV_HOME = "${homeDirectory}/.local/share/venvs";
        SSL_CERT_FILE = caCert;
        REQUESTS_CA_BUNDLE = caCert;
        NIX_LD_LIBRARY_PATH = ldLibPath;
        NIX_LD = dynamicLinker;
        CC = "${gcc}/bin/gcc";
        LD = "${binutils}/bin/ld";
      };
    };
    manzil.users."${userName}".files = {
      ".config/python/pythonrc" = {
        text = ''
          # Python 3.13+ handles history natively via PYTHON_HISTORY env var.
          # This file is kept for any remaining startup customisation.
        '';
      };
    };
    # PATH must be prepended at shell start: finix renders
    # environment.variables with escapeShellArg, so "$PATH" would land
    # literal (modules/environment/shells/default.nix in the finix input).
    user.shell.rcExtra = lib.mkAfter ''
      PATH="${pythonUserBase}/bin:$PATH"

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
  };
}
