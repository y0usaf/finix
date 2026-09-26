{
  config,
  lib,
  ...
}: let
  inherit (config.user.dev.prompts) body;

  phiSystemPrompt = ''
    <role>
      Phi coding assistant.
    </role>

    ${body}
  '';
in {
  config = lib.mkIf config.user.dev.phi.enable {
    manzil.users."${config.user.name}".files.".config/phi/SYSTEM.md".text = phiSystemPrompt;
  };
}
