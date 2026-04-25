{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs) stdenv;
  handyCfg = config.user.programs.handy;
in {
  options.user.programs.handy = {
    enable = lib.mkEnableOption "Handy speech-to-text";
    transcribeBinding = lib.mkOption {
      type = lib.types.str;
      default = "ctrl+space";
      description = "Handy global shortcut for transcription";
    };
  };

  config = lib.mkIf handyCfg.enable {
    patchix = {
      enable = true;
      users."${config.user.name}".patches.".local/share/com.pais.handy/settings_store.json" = {
        format = "json";
        value = {
          settings = {
            push_to_talk = true;
            audio_feedback = false;
            keyboard_implementation = "handy_keys";
            bindings = {
              transcribe = {
                id = "transcribe";
                name = "Transcribe";
                description = "Converts your speech into text.";
                default_binding = "ctrl+space";
                current_binding = handyCfg.transcribeBinding;
              };
            };
          };
        };
      };
    };

    systemd.services."patchix-${config.user.name}".preStart = ''
      settings_dir="${config.user.homeDirectory}/.local/share/com.pais.handy"
      settings_file="$settings_dir/settings_store.json"

      mkdir -p "$settings_dir"

      if [ ! -e "$settings_file" ]; then
        cp ${pkgs.writeText "handy-settings-store.json" (builtins.toJSON {
        settings = {
          push_to_talk = true;
          audio_feedback = false;
          keyboard_implementation = "handy_keys";
          external_script_path = null;
          bindings = {
            transcribe = {
              id = "transcribe";
              name = "Transcribe";
              description = "Converts your speech into text.";
              default_binding = "ctrl+space";
              current_binding = handyCfg.transcribeBinding;
            };
            transcribe_with_post_process = {
              id = "transcribe_with_post_process";
              name = "Transcribe with Post-Processing";
              description = "Converts your speech into text and applies AI post-processing.";
              default_binding = "ctrl+shift+space";
              current_binding = "ctrl+shift+space";
            };
            cancel = {
              id = "cancel";
              name = "Cancel";
              description = "Cancels the current recording.";
              default_binding = "escape";
              current_binding = "escape";
            };
          };
        };
      })} "$settings_file"
      fi
    '';

    environment.systemPackages = [
      flakeInputs.handy.packages."${stdenv.hostPlatform.system}".default
      pkgs.wtype # Ensure wtype is available for Wayland text injection
    ];
  };
}
