# instructify plugin - Config-driven hook instruction injector
{
  name = "instructify";
  version = "1.1.0";
  description = "Config-driven hook instruction injector - maps hook events to system reminders";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
  dataFiles = {
    "instructions.json" = import ./instructions.nix;
  };
}
