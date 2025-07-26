{
  config,
  lib,
  ...
}: let
  cfg = config.home.shell.aliases;
  inherit (config.user) name homeDirectory nixosConfigDirectory;
in {
  options.home.shell.aliases = {enable = lib.mkEnableOption "Enable base aliases";};
  config = lib.mkIf cfg.enable {
    # nix-maid (legacy)
    users.users.${name}.maid.file.home = {
      ".config/zsh/aliases/android.zsh".text = ''alias adb="HOME=\"$XDG_DATA_HOME/android\" adb"'';
      ".config/zsh/aliases/download.zsh".text = ''alias wget="wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\""'';
      ".config/zsh/aliases/version-control.zsh".text = ''alias svn="svn --config-dir \"$XDG_CONFIG_HOME/subversion\"" alias hmpush="git -C ${nixosConfigDirectory} push origin main --force" alias hmpull="git -C ${nixosConfigDirectory} fetch origin && git -C ${nixosConfigDirectory} reset --hard origin/main" '';
      ".config/zsh/aliases/javascript.zsh".text = ''alias yarn="yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\""'';
      ".config/zsh/aliases/media.zsh".text = ''alias mocp="mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\""'';
      ".config/zsh/aliases/navigation.zsh".text = ''alias cat="bat" alias cattree="${nixosConfigDirectory}/lib/scripts/cattree.sh" alias l.="lsd -A | grep -E \"^\\.\"" alias la="lsd -A --color=always --group-dirs=first --icon=always" alias ll="lsd -l --color=always --group-dirs=first --icon=always" alias ls="lsd -lA --color=always --group-dirs=first --icon=always" alias lt="lsd -A --tree --color=always --group-dirs=first --icon=always" '';
      ".config/zsh/aliases/system.zsh".text = ''alias userctl="systemctl --user" alias hmfail="journalctl -u home-manager-${name}.service -n 20 --no-pager" alias pkgs="nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i" alias pkgcount="nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l" alias hwconfig="sudo nixos-generate-config --show-hardware-config" alias gpupower="sudo nvidia-smi -pl" '';
      ".config/zsh/aliases/search.zsh".text = ''alias grep="grep --color=auto" alias dir="dir --color=auto" alias egrep="grep -E --color=auto" alias fgrep="grep -F --color=auto" '';
      ".config/zsh/aliases/development.zsh".text = ''alias lintcheck="clear; statix check .; deadnix ." alias lintfix="clear; statix fix .; deadnix ." alias ide="zellij --layout ${config.user.configDirectory}/zellij/layouts/ide.kdl" alias opencode="${homeDirectory}/.npm-global/bin/opencode" '';
    };
    # hjem (new)
    hjem.users.${name}.files = {
      ".config/zsh/aliases/android.zsh".text = ''alias adb="HOME=\"$XDG_DATA_HOME/android\" adb"'';
      ".config/zsh/aliases/download.zsh".text = ''alias wget="wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\""'';
      ".config/zsh/aliases/version-control.zsh".text = ''alias svn="svn --config-dir \"$XDG_CONFIG_HOME/subversion\"" alias hmpush="git -C ${nixosConfigDirectory} push origin main --force" alias hmpull="git -C ${nixosConfigDirectory} fetch origin && git -C ${nixosConfigDirectory} reset --hard origin/main" '';
      ".config/zsh/aliases/javascript.zsh".text = ''alias yarn="yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\""'';
      ".config/zsh/aliases/media.zsh".text = ''alias mocp="mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\""'';
      ".config/zsh/aliases/navigation.zsh".text = ''alias cat="bat" alias cattree="${nixosConfigDirectory}/lib/scripts/cattree.sh" alias l.="lsd -A | grep -E \"^\\.\"" alias la="lsd -A --color=always --group-dirs=first --icon=always" alias ll="lsd -l --color=always --group-dirs=first --icon=always" alias ls="lsd -lA --color=always --group-dirs=first --icon=always" alias lt="lsd -A --tree --color=always --group-dirs=first --icon=always" '';
      ".config/zsh/aliases/system.zsh".text = ''alias userctl="systemctl --user" alias hmfail="journalctl -u home-manager-${name}.service -n 20 --no-pager" alias pkgs="nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i" alias pkgcount="nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l" alias hwconfig="sudo nixos-generate-config --show-hardware-config" alias gpupower="sudo nvidia-smi -pl" '';
      ".config/zsh/aliases/search.zsh".text = ''alias grep="grep --color=auto" alias dir="dir --color=auto" alias egrep="grep -E --color=auto" alias fgrep="grep -F --color=auto" '';
      ".config/zsh/aliases/development.zsh".text = ''alias lintcheck="clear; statix check .; deadnix ." alias lintfix="clear; statix fix .; deadnix ." alias ide="zellij --layout ${config.user.configDirectory}/zellij/layouts/ide.kdl" alias opencode="${homeDirectory}/.npm-global/bin/opencode" '';
    };
  };
}
