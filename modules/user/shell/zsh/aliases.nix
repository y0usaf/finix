{
  config,
  nixosConfigDirectory,
}:
{
  # XDG compliance
  wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
}
// (
  if config.hardware.nvidia.enable
  then {
    nvidia-settings = ''nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'';
    gpupower = "sudo nvidia-smi -pl";
  }
  else {}
)
// {
  # Android
  adb = ''HOME="$XDG_DATA_HOME/android" adb'';

  # Development
  lintcheck = "clear; statix check .; deadnix .";
  lintfix = "clear; statix fix .; deadnix .";
  clauded = "claude --dangerously-skip-permissions";

  # Media
  mocp = ''mocp -M "$XDG_CONFIG_HOME/moc" -O MOCDir="$XDG_CONFIG_HOME/moc"'';

  # JavaScript
  yarn = ''yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'';

  # Navigation
  "l." = "lsd -A | grep -E \"^\\\\.\"";
  la = "lsd -A --color=always --group-dirs=first --icon=always";
  ll = "lsd -l --color=always --group-dirs=first --icon=always";
  ls = "lsd -lA --color=always --group-dirs=first --icon=always";
  lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

  # Search
  grep = "rg --color auto";
  dir = "dir --color=auto";
  egrep = "rg --color auto";
  fgrep = "rg -F --color auto";

  # System
  pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | rg -i";
  pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";

  # Version control
  svn = ''svn --config-dir "$XDG_CONFIG_HOME/subversion"'';
  hmpush = "git -C ${nixosConfigDirectory} push origin main --force";
  hmpull = "git -C ${nixosConfigDirectory} fetch origin && git -C ${nixosConfigDirectory} reset --hard origin/main";
}
