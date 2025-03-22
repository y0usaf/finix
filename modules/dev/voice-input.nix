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
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.dev.voice-input = {
    enable = lib.mkEnableOption "Voice input capabilities";

    model = lib.mkOption {
      type = lib.types.str;
      default = "tiny";
      description = "Whisper model to use (tiny, base, small, medium, large)";
    };

    recordTime = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Maximum recording time in seconds";
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
      libnotify # for notifications
      wtype # for typing text into active window (Wayland compatible)
      xdotool # for typing text into active window (X11 compatible)
    ];

    # Add shell aliases
    programs.zsh.shellAliases = {
      dictate = "voice-input";
    };

    # Add shell functions and scripts
    programs.zsh.initExtra = ''
                  # Function to transcribe voice to text using whisper
                  voice-to-text() {
                    echo "🎤 Listening... (speak and then press Ctrl+C when done)"

                    # Create a temporary file for the audio
                    TEMP_AUDIO=$(mktemp --suffix=.wav)

                    # Record audio to the temporary file
                    echo "Recording to $TEMP_AUDIO..."
                    arecord -f cd -t wav -d ${toString cfg.recordTime} "$TEMP_AUDIO"

                    # Check if recording was successful
                    if [ -s "$TEMP_AUDIO" ]; then
                      echo "Transcribing audio..."
                      devenv bash -c "whisper-cpp -m ${cfg.model} -f \"$TEMP_AUDIO\" -nt"
                    else
                      echo "❌ Error: No audio recorded or file is empty"
                    fi

                    # Clean up
                    rm -f "$TEMP_AUDIO"
                  }

                  # Create a voice-input script that transcribes and types the text
                  if [ ! -f "$HOME/.local/bin/voice-input" ]; then
                    cat > "$HOME/.local/bin/voice-input" << EOF
      #!/usr/bin/env bash

      # Display notification
      notify-send "Voice Input" "🎤 Listening... (speak for up to ${toString cfg.recordTime} seconds)"

      # Create a temporary file for the audio
      TEMP_AUDIO=\$(mktemp --suffix=.wav)

      # Record audio to the temporary file
      echo "Recording to \$TEMP_AUDIO..."
      arecord -f cd -t wav -d ${toString cfg.recordTime} "\$TEMP_AUDIO"

      # Check if recording was successful
      if [ -s "\$TEMP_AUDIO" ]; then
        # Transcribe with whisper
        echo "Transcribing audio..."
        TRANSCRIPTION=\$(devenv bash -c "whisper-cpp -m ${cfg.model} -f \"\$TEMP_AUDIO\" -nt")

        # Trim whitespace
        TRANSCRIPTION=\$(echo "\$TRANSCRIPTION" | xargs)

        if [ -n "\$TRANSCRIPTION" ]; then
          # Type the transcribed text into the active window
          notify-send "Voice Input" "✓ Typing: \$TRANSCRIPTION"
          sleep 0.5  # Give time to switch back to the target window

          # Detect if we're running on Wayland or X11
          if [ -n "\$WAYLAND_DISPLAY" ]; then
            # Use wtype for Wayland
            wtype "\$TRANSCRIPTION"
          else
            # Use xdotool for X11
            xdotool type --clearmodifiers "\$TRANSCRIPTION"
          fi
        else
          notify-send "Voice Input" "❌ No text transcribed"
        fi
      else
        notify-send "Voice Input" "❌ Error: No audio recorded or file is empty"
      fi

      # Clean up
      rm -f "\$TEMP_AUDIO"
      EOF
                    chmod +x "$HOME/.local/bin/voice-input"
                  fi
    '';
  };
}
