{config, ...}: let
  body = "${config.user.dev.prompts.shared}\n";
in {
  manzil.users."${config.user.name}".files = {
    ".config/phi/APPEND_SYSTEM.md".text = body;
    ".local/state/boar/agent/APPEND_SYSTEM.md".text = body;
    ".local/state/boar-rs/agent/APPEND_SYSTEM.md".text = body;
    ".pi/agent/APPEND_SYSTEM.md".text = body;
  };
}
