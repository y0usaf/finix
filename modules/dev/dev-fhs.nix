###############################################################################
# Universal FHS Development Environment
# Provides a standard Linux filesystem hierarchy for development tools
# - Compatible with Python, Node.js, CUDA, and other development tools
# - Allows using UV for Python environment management within FHS
# - Creates a consistent development environment across NixOS systems
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.dev.fhs;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.dev.fhs = {
    enable = lib.mkEnableOption "FHS development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Create the FHS environment for development
    home.packages = let
      cudaPkgs =
        if (config.modules.core.nvidia.cuda.enable or false)
        then [
          pkgs.cudaPackages.cudatoolkit
          pkgs.cudaPackages.cuda_nvcc
        ]
        else [];
    in [
      (pkgs.buildFHSEnv {
        name = "devenv";
        targetPkgs = pkgs:
          with pkgs;
            [
              # Core development tools
              gcc
              binutils
              gnumake
              cmake
              pkg-config

              # Python ecosystem
              python3
              python312
              python311
              uv
              python3Packages.pip
              python3Packages.setuptools
              python3Packages.wheel
              python3Packages.distutils-extra

              # Build dependencies for Python packages
              ninja
              meson
              ffmpeg

              # Node.js ecosystem
              nodejs_20

              # System libraries commonly needed
              stdenv.cc.cc.lib
              zlib
              libGL
              glib
              xorg.libX11
              xorg.libXext
              xorg.libXrender

              # SSL certificates
              cacert

              # Additional useful tools
              git
              ripgrep
              fd

              # Add zsh to the environment
              zsh

              # Add whisper for voice-to-text
              openai-whisper-cpp
              pulseaudio # for audio capture
              libnotify # for notifications
              xdotool # for typing text into active window
            ]
            ++ cudaPkgs;

        profile = ''
          # Set up Python paths
          export PYTHONUSERBASE="$HOME/.local/python"
          export PIP_CACHE_DIR="$HOME/.cache/pip"
          export VIRTUAL_ENV_HOME="$HOME/.local/venvs"

          # Set up build environment variables
          export SETUPTOOLS_USE_DISTUTILS=local

          # Set up SSL certificates
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

          # Set up npm paths
          export NPM_CONFIG_PREFIX="$HOME/.local/npm"
          export NPM_CONFIG_CACHE="$HOME/.cache/npm"

          # Set compiler flags
          export CC=gcc
          export CXX=g++

          # Add local bin to PATH
          export PATH="$HOME/.local/bin:$PATH"
        '';

        # Use zsh as the shell and print the activation message only once
        runScript = "zsh -c 'echo \"🏗️ Development environment activated!\" && exec zsh'";
      })
    ];

    ###########################################################################
    # Shell Configuration
    ###########################################################################
    programs.zsh = {
      shellAliases = {
        dev = "devenv";
        fhs = "devenv";
        dictate = "voice-input"; # Add alias for voice input
      };

      initExtra = ''
                # ----------------------------
                # FHS Development Environment
                # ----------------------------

                # Function to create a UV environment within the FHS env
                uv-init() {
                  if [ -z "$1" ]; then
                    echo "Usage: uv-init <environment-name>"
                    return 1
                  fi

                  ENV_NAME="$1"
                  ENV_PATH="$HOME/.local/venvs/$ENV_NAME"

                  mkdir -p "$HOME/.local/venvs"

                  devenv bash -c "uv venv $ENV_PATH && echo 'Created UV environment at $ENV_PATH'"

                  cat > "$HOME/.local/bin/$ENV_NAME" << EOF
        #!/usr/bin/env bash
        devenv bash -c 'source $ENV_PATH/bin/activate && exec bash'
        EOF
                  chmod +x "$HOME/.local/bin/$ENV_NAME"

                  echo "🚀 Created environment '$ENV_NAME'. Run '$ENV_NAME' to activate."
                }

                # Ensure local bin directory exists and is in PATH
                mkdir -p "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"

                # Function to transcribe voice to text using whisper
                voice-to-text() {
                  echo "🎤 Listening... (speak and then press Ctrl+C when done)"
                  devenv whisper-cpp -m tiny -f <(arecord -f cd -t wav -d 10) -nt
                }

                # Create a voice-input script that transcribes and types the text
                if [ ! -f "$HOME/.local/bin/voice-input" ]; then
                  cat > "$HOME/.local/bin/voice-input" << 'EOF'
        #!/usr/bin/env bash

        # Display notification
        notify-send "Voice Input" "🎤 Listening... (speak and press Ctrl+C when done)"

        # Record audio and transcribe with whisper
        TRANSCRIPTION=$(devenv bash -c "whisper-cpp -m tiny -f <(arecord -f cd -t wav -d 10 2>/dev/null) -nt")

        # Trim whitespace
        TRANSCRIPTION=$(echo "$TRANSCRIPTION" | xargs)

        if [ -n "$TRANSCRIPTION" ]; then
          # Type the transcribed text into the active window
          notify-send "Voice Input" "✓ Typing: $TRANSCRIPTION"
          sleep 0.5  # Give time to switch back to the target window
          xdotool type --clearmodifiers "$TRANSCRIPTION"
        else
          notify-send "Voice Input" "❌ No text transcribed"
        fi
        EOF
                  chmod +x "$HOME/.local/bin/voice-input"
                fi
      '';
    };

    ###########################################################################
    # Activation Scripts
    ###########################################################################
    home.activation.createLocalBin = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.local/bin
      $DRY_RUN_CMD mkdir -p $HOME/.local/venvs
    '';
  };
}
