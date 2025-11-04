# NixOS-specific aliases
_: {
  # Android development
  adb = ''HOME="$XDG_DATA_HOME/android" adb'';

  # Music on console (Linux-specific)
  mocp = ''mocp -M "$XDG_CONFIG_HOME/moc" -O MOCDir="$XDG_CONFIG_HOME/moc"'';

  # Yarn XDG compliance
  yarn = ''yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'';

  # Nix store queries
  pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | rg -i";
  pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
}
