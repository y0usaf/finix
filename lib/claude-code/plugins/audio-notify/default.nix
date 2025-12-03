# audio-notify plugin - plays sound on completion
{
  name = "audio-notify";
  version = "1.0.0";
  description = "Audio notifications for Claude Code events";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}
