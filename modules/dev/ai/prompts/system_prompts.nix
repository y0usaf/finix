{config, ...}: let
  body = "${config.user.dev.prompts.shared}\n";
in {
  user.files = {
    ".config/phi/APPEND_SYSTEM.md".text = body;
    ".local/state/boar/agent/APPEND_SYSTEM.md".text = body;
    ".local/state/boar-rs/agent/APPEND_SYSTEM.md".text = body;
    ".pi/agent/APPEND_SYSTEM.md".text = body;
  };
}
