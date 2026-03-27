{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) homeDirectory shell;
  inherit (pkgs) cacert gcc binutils;
  dynamicLinker = pkgs.stdenv.cc.bintools.dynamicLinker;
  caCert = "${cacert}/etc/ssl/certs/ca-bundle.crt";
in {
  options.user.dev.python = {
    enable = lib.mkEnableOption "Python development environment";
  };
  config = lib.mkIf config.user.dev.python.enable {
    environment.systemPackages = [
      pkgs.python3
      pkgs.uv
      pkgs.ninja
      pkgs.meson
      pkgs.pkg-config
      cacert
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libGL
      pkgs.glib
      pkgs.libx11
      pkgs.libxext
      pkgs.libxrender
      gcc
      binutils
    ];
    usr.files = let
      ldLibPath = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.libx11
        pkgs.libxext
        pkgs.libxrender
      ];
    in
      lib.optionalAttrs shell.zsh.enable {
        ".config/zsh/.zshenv" = {
          clobber = true;
          text = lib.mkAfter ''
            export PYTHONUSERBASE="${homeDirectory}/.local/share/python"
            export PIP_CACHE_DIR="${homeDirectory}/.cache/pip"
            export VIRTUAL_ENV_HOME="${homeDirectory}/.local/share/venvs"
            export SSL_CERT_FILE="${caCert}"
            export REQUESTS_CA_BUNDLE="${caCert}"
            export NIX_LD_LIBRARY_PATH="${ldLibPath}"
            export NIX_LD="${dynamicLinker}"
            export CC="${gcc}/bin/gcc"
            export LD="${binutils}/bin/ld"
            export PATH="$PYTHONUSERBASE/bin:$PATH"
          '';
        };
        ".config/zsh/.zshrc" = {
          clobber = true;
          text = lib.mkAfter ''
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
      }
      // lib.optionalAttrs shell.nushell.enable {
        ".config/nushell/env.nu" = {
          clobber = true;
          text = lib.mkAfter ''
            $env.PYTHONUSERBASE = "${homeDirectory}/.local/share/python"
            $env.PIP_CACHE_DIR = "${homeDirectory}/.cache/pip"
            $env.VIRTUAL_ENV_HOME = "${homeDirectory}/.local/share/venvs"
            $env.SSL_CERT_FILE = "${caCert}"
            $env.REQUESTS_CA_BUNDLE = "${caCert}"
            $env.NIX_LD_LIBRARY_PATH = "${ldLibPath}"
            $env.NIX_LD = "${dynamicLinker}"
            $env.CC = "${gcc}/bin/gcc"
            $env.LD = "${binutils}/bin/ld"
            $env.PATH = ($env.PATH | prepend $"($env.PYTHONUSERBASE)/bin")
          '';
        };
        ".config/nushell/config.nu" = {
          clobber = true;
          text = lib.mkAfter ''
            alias py = python3
            alias pip = pip3
            alias uv-init = uv init
            alias uv-add = uv add
            alias uv-run = uv run
            def mkvenv [name?: string] {
              if ($name | is-empty) {
                ^python3 -m venv venv
              } else {
                ^python3 -m venv $name
              }
            }
            def workon [name?: string] {
              if ($name | is-empty) {
                if ("venv" | path exists) {
                  load-env {
                    VIRTUAL_ENV: $"(pwd)/venv"
                    PATH: ($env.PATH | prepend $"(pwd)/venv/bin")
                  }
                } else {
                  print "No venv directory found"
                }
              } else {
                let venv_path = $"($env.VIRTUAL_ENV_HOME)/($name)"
                if ($venv_path | path exists) {
                  load-env {
                    VIRTUAL_ENV: $venv_path
                    PATH: ($env.PATH | prepend $"($venv_path)/bin")
                  }
                } else {
                  print $"Virtual environment ($name) not found"
                }
              }
            }
          '';
        };
      };
    systemd.tmpfiles.rules = let
      userName = config.user.name;
    in [
      "d ${homeDirectory}/.local/share/python 0755 ${userName} ${userName} - -"
      "d ${homeDirectory}/.cache/pip 0755 ${userName} ${userName} - -"
      "d ${homeDirectory}/.local/share/venvs 0755 ${userName} ${userName} - -"
    ];
  };
}
