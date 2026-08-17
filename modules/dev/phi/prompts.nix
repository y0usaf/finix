# Phi system-prompt overrides.
#
# Writes ~/.config/phi/SYSTEM.md, which phi-rlm's prompt-override discovery
# (`discover_prompt_overrides`) loads as the system-prompt identity override
# (see crates/phi-rlm/src/prompts/overrides.rs). Phi's builder then appends its
# own REPL-tools, mechanics, project-context, and environment sections after
# this identity block.
#
# The behavioral body (<reader>, <style>, <explain>, <work>) is shared with the
# pi coding agent — source of truth: modules/dev/phi/prompt-body.nix. Keep the
# two in sync.
{
  config,
  lib,
  ...
}: let
  body = (import ./prompt-body.nix {}).promptBody;

  phiSystemPrompt = ''
    <role>
      Phi coding assistant. Get the work done, and leave the user understanding why it
      worked. A correct answer the user cannot reason about later is a failed answer.
    </role>

    ${body}
  '';
in {
  config = lib.mkIf config.user.dev.phi.enable {
    manzil.users."${config.user.name}".files.".config/phi/SYSTEM.md".text = phiSystemPrompt;
  };
}
