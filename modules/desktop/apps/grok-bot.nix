{
  config,
  inputPackages,
  ...
}: {
  user.persist.directories = [
    ".config/silvabot"
    ".grokbot"
    ".local/share/silvabot"
    ".local/state/silvabot"
  ];
  environment.systemPackages = [
    (inputPackages.grok-bot.default.override {
      commandLineArgs = ["--force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale}"];
    })
  ];
}
