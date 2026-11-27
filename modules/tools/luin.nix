{
  config,
  inputPackages,
  lib,
  ...
}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  luinPkg = inputPackages.luin.default;
in {
  environment = {
    systemPackages = [luinPkg inputPackages.luin.luin-pin inputPackages.luin.luinitctl];
    etc."profile.d/luin-path.sh".text = ''
      case ":$PATH:" in
        *":$HOME/.local/state/luin/current/bin:"*) ;;
        *) export PATH="$HOME/.local/state/luin/current/bin:$PATH" ;;
      esac
    '';
  };

  user = {
    persist.directories = [
      "luin"
      ".local/state/luin"
      ".config/luin"
    ];
    shell.rcExtra = lib.mkBefore ''
      case ":$PATH:" in
        *":$HOME/.local/state/luin/current/bin:"*) ;;
        *) export PATH="$HOME/.local/state/luin/current/bin:$PATH" ;;
      esac
    '';
  };

  finit.tasks.luin-deploy = {
    description = "deploy active luin generation for ${userName}";
    user = userName;
    group = "users";
    log = true;
    conditions = lib.optional (config.finix.persistence.homeCondition != null) config.finix.persistence.homeCondition;
    environment.HOME = home;
    command = "${luinPkg}/bin/luin deploy ${home}/.local/state/luin ${home}";
  };
}
