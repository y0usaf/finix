{
  config,
  lib,
  pkgs,
  ...
}: {
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
      lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/.zshenv" = {
          clobber = true;
          text = lib.mkAfter ''
            export PYTHONUSERBASE="${config.user.homeDirectory}/.local/share/python"
            export PIP_CACHE_DIR="${config.user.homeDirectory}/.cache/pip"
            export VIRTUAL_ENV_HOME="${config.user.homeDirectory}/.local/share/venvs"
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NIX_LD_LIBRARY_PATH="${ldLibPath}"
            export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
            export CC="${pkgs.gcc}/bin/gcc"
            export LD="${pkgs.binutils}/bin/ld"
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
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/env.nu" = {
          clobber = true;
          text = lib.mkAfter ''
            $env.PYTHONUSERBASE = "${config.user.homeDirectory}/.local/share/python"
            $env.PIP_CACHE_DIR = "${config.user.homeDirectory}/.cache/pip"
            $env.VIRTUAL_ENV_HOME = "${config.user.homeDirectory}/.local/share/venvs"
            $env.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            $env.REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            $env.NIX_LD_LIBRARY_PATH = "${ldLibPath}"
            $env.NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}"
            $env.CC = "${pkgs.gcc}/bin/gcc"
            $env.LD = "${pkgs.binutils}/bin/ld"
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
    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/python 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/pip 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.local/share/venvs 0755 ${config.user.name} ${config.user.name} - -"
    ];
  };
}
