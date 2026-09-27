{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".barony"
    ".config/bolt-launcher"
    ".config/unity3d"
    ".local/share/.Wurst encryption"
    ".local/share/.renpy"
    ".local/share/Baba_Is_You"
    ".local/share/Brotato"
    ".local/share/CassetteBeasts"
    ".local/share/Celeste"
    ".local/share/HallsOfTorment"
    ".local/share/Noobs Are Coming (Save)"
    ".local/share/PrismLauncher"
    ".local/share/Rocket League"
    ".local/share/Smart Code ltd"
    ".local/share/SteamWorld Heist"
    ".local/share/Ultrapool"
    ".local/share/YourOnlyMoveIsHUSTLE"
    ".local/share/aspyr-media"
    ".local/share/balatroai"
    ".local/share/binding of isaac rebirth"
    ".local/share/bolt-launcher"
    ".local/share/com.overboy.noobsarecoming"
    ".local/share/godot/app_userdata"
    ".local/share/hackerpg"
    ".local/share/lootplot"
    ".local/share/osu"
    ".local/share/shapez.io"
    ".local/share/shipofharkinian"
    ".local/share/skua-wine"
    ".local/share/wine"
  ];
  environment.systemPackages = [
    pkgs.prismlauncher
    pkgs.gamescope
    pkgs.gamemode
    pkgs.protontricks
  ];
}
