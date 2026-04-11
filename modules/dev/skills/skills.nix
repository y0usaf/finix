_: {
  config.lib.ai.skills = {
    agent-slack = import ./agent-slack.nixlib;
    gh = import ./gh.nixlib;
    linear-cli = import ./linear-cli.nixlib;
  };
}
