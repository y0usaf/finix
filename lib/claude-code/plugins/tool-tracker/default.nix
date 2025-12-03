# tool-tracker plugin - tracks tool usage per session
{
  name = "tool-tracker";
  version = "1.0.0";
  description = "Tracks tool usage per session for analysis";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}
