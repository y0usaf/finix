{inputPackages, ...}: let
  inherit (inputPackages) silva;
in {
  user.persist.directories = [
    ".config/silva"
    ".local/share/silva"
    ".local/state/silva"
  ];
  environment.systemPackages = [
    silva.silva-up
    silva.tui
    silva.kitty
  ];
}
