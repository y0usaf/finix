{
  config,
  lib,
  pkgs,
  ...
}: {
  claudeSettings = {
    includeCoAuthoredBy = false;
    outputStyle = "explanatory";
    model = "claude-sonnet-4-20250514";
    statusLine = {
      type = "command";
      command = "npx ccusage statusline";
    };
  };
}
