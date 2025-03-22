###############################################################################
# Voice Input Module
# Provides voice-to-text input capabilities using local Whisper model
# - Transcribes speech to text using OpenAI's Whisper model
# - Types the transcribed text into the active window
# - Works on both Wayland and X11
# - Depends on the FHS development environment
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.dev.voice-input;

  # Define model paths
  modelUrls = {
    tiny = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin";
    base = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
    small = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
    medium = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin";
    large = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin";
  };

  modelUrl = modelUrls.${cfg.model} or modelUrls.tiny;
  modelDir = "$HOME/.local/share/whisper-models";
  modelPath = "${modelDir}/ggml-${cfg.model}.bin";
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.dev.voice-input = {
    enable = lib.mkEnableOption "Voice input capabilities";

    model = lib.mkOption {
      type = lib.types.enum ["tiny" "base" "small" "medium" "large"];
      default = "tiny";
      description = "Whisper model to use (tiny, base, small, medium, large)";
    };

    recordTime = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Maximum recording time in seconds";
    };

    silenceThreshold = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Seconds of silence before automatically stopping recording";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable debug logging";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Add necessary packages
    home.packages = with pkgs; [
      # Add packages needed for voice input
      openai-whisper-cpp
      pulseaudio # for audio capture
      alsa-utils # for arecord command
      sox # for silence detection
      libnotify # for notifications
      wtype # for typing text into active window (Wayland compatible)
      xdotool # for typing text into active window (X11 compatible)
      curl # for downloading model files
    ];

    # Add shell aliases
    programs.zsh.shellAliases = {
      dictate = "voice-input";
    };

    # Add shell functions and scripts
    programs.zsh.initExtra = ''
                  # Function to download whisper model if not already present
                  download_whisper_model() {
                    mkdir -p "${modelDir}"
                    if [ ! -f "${modelPath}" ]; then
                      echo "Downloading whisper model ${cfg.model}..."
                      curl -L "${modelUrl}" -o "${modelPath}"
                      echo "Model downloaded to ${modelPath}"
                    fi
                  }

                  # Ensure model is downloaded on shell init
                  download_whisper_model

                  # Function to transcribe voice to text using whisper
                  voice-to-text() {
                    echo "🎤 Listening... (speak and then stop to auto-detect silence)"

                    # Ensure model is downloaded
                    download_whisper_model

                    # Create a temporary file for the audio
                    TEMP_AUDIO=$(mktemp --suffix=.wav)
                    TEMP_LOG=$(mktemp --suffix=.log)

                    # Record audio to the temporary file with silence detection
                    echo "Recording to $TEMP_AUDIO..."
                    rec -t wav "$TEMP_AUDIO" silence 1 0.1 3% 1 ${toString cfg.silenceThreshold} 3%

                    # Check if recording was successful
                    if [ -s "$TEMP_AUDIO" ]; then
                      echo "Transcribing audio..."
                      MODEL_PATH_EXPANDED=$(eval echo "${modelPath}")
                      echo "Running: whisper-cpp -m \"$MODEL_PATH_EXPANDED\" -f \"$TEMP_AUDIO\" -nt"

                      # Run whisper with detailed output
                      TRANSCRIPTION=$(devenv bash -c "whisper-cpp -m \"$MODEL_PATH_EXPANDED\" -f \"$TEMP_AUDIO\" -nt 2>&1 | tee $TEMP_LOG")

                      # Display the transcription result
                      echo "Transcription result:"
                      echo "$TRANSCRIPTION"

                      # If debug is enabled, show the log
                      if [ ${toString (
        if cfg.debug
        then "true"
        else "false"
      )} = "true" ]; then
                        echo "Debug log:"
                        cat "$TEMP_LOG"
                      fi
                    else
                      echo "❌ Error: No audio recorded or file is empty"
                    fi

                    # Clean up
                    rm -f "$TEMP_AUDIO"
                    rm -f "$TEMP_LOG"
                  }

                  # Create a voice-input script that transcribes and types the text
                  if [ ! -f "$HOME/.local/bin/voice-input" ]; then
                    cat > "$HOME/.local/bin/voice-input" << EOF
      #!/usr/bin/env bash

      # Define model paths
      MODEL_DIR="$HOME/.local/share/whisper-models"
      MODEL_PATH="$MODEL_DIR/ggml-${cfg.model}.bin"
      MODEL_URL="${modelUrl}"

      # Ensure whisper model is downloaded
      mkdir -p "$MODEL_DIR"
      if [ ! -f "$MODEL_PATH" ]; then
        notify-send "Voice Input" "Downloading whisper model ${cfg.model}..."
        curl -L "$MODEL_URL" -o "$MODEL_PATH"
        notify-send "Voice Input" "Model downloaded to $MODEL_PATH"
      fi

      # Display notification
      notify-send "Voice Input" "🎤 Listening... (speak and then pause to auto-detect silence)"

      # Create a temporary file for the audio
      TEMP_AUDIO=$(mktemp --suffix=.wav)
      TEMP_LOG=$(mktemp --suffix=.log)

      # Record audio to the temporary file with silence detection
      echo "Recording to $TEMP_AUDIO..."
      rec -t wav "$TEMP_AUDIO" silence 1 0.1 3% 1 ${toString cfg.silenceThreshold} 3%

      # Check if recording was successful
      if [ -s "$TEMP_AUDIO" ]; then
        # Transcribe with whisper
        echo "Transcribing audio..."
        echo "Running: whisper-cpp -m \"$MODEL_PATH\" -f \"$TEMP_AUDIO\" -nt"

        # Run whisper with detailed output
        TRANSCRIPTION=$(devenv bash -c "whisper-cpp -m \"$MODEL_PATH\" -f \"$TEMP_AUDIO\" -nt 2>&1 | tee $TEMP_LOG")

        # Log the transcription result
        echo "Transcription result:"
        echo "$TRANSCRIPTION"

        # If debug is enabled, show the log
        if [ ${toString (
        if cfg.debug
        then "true"
        else "false"
      )} = "true" ]; then
          echo "Debug log:"
          cat "$TEMP_LOG"
        fi

        # Trim whitespace
        TRANSCRIPTION=$(echo "$TRANSCRIPTION" | xargs)

        if [ -n "$TRANSCRIPTION" ]; then
          # Type the transcribed text into the active window
          notify-send "Voice Input" "✓ Typing: $TRANSCRIPTION"
          sleep 0.5  # Give time to switch back to the target window

          # Detect if we're running on Wayland or X11
          if [ -n "$WAYLAND_DISPLAY" ]; then
            # Use wtype for Wayland
            wtype "$TRANSCRIPTION"
          else
            # Use xdotool for X11
            xdotool type --clearmodifiers "$TRANSCRIPTION"
          fi
        else
          notify-send "Voice Input" "❌ No text transcribed"
        fi
      else
        notify-send "Voice Input" "❌ Error: No audio recorded or file is empty"
      fi

      # Clean up
      rm -f "$TEMP_AUDIO"
      rm -f "$TEMP_LOG"
      EOF
                    chmod +x "$HOME/.local/bin/voice-input"
                  fi
    '';

    # Create the model directory
    home.activation.createWhisperModelDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.local/share/whisper-models
    '';
  };
}
