{
  pkgs,
  flakeInputs,
  ...
}: {
  environment = {
    variables.HERMES_HOME = "/home/y0usaf/.hermes";
    systemPackages = [
      flakeInputs.hermes-agent.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };

  user.dev = {
    claude-code = {
      enable = true;
      model = "sonnet";
      subagentModel = "sonnet";
    };
    codex = {
      enable = true;
      model = "gpt-5.4";
      settings.personality = "pragmatic";
    };
    codex-cli.enable = true;
    pi.enable = true;
    nvim.enable = true;
    docker.enable = true;
  };
}
