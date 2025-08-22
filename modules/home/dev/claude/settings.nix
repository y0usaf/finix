{
  config,
  lib,
  pkgs,
  ...
}: {
  claudeSettings = {
    includeCoAuthoredBy = false;
    outputStyle = "structured";
    statusLine = {
      type = "command";
      command = "npx ccusage statusline";
    };
  };
}
