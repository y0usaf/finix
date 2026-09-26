_: {
  config.user.appearance.wallust = {
    targets = {
      "shell-colors" = {
        template = "shell-colors.sh";
        target = "~/.cache/wallust/shell-colors.sh";
      };
    };

    templates."shell-colors.sh" = ''

      WALLUST_COLOR0=$'\033[38;5;0m'
      WALLUST_COLOR1=$'\033[38;5;1m'
      WALLUST_COLOR2=$'\033[38;5;2m'
      WALLUST_COLOR3=$'\033[38;5;3m'
      WALLUST_COLOR4=$'\033[38;5;4m'
      WALLUST_COLOR5=$'\033[38;5;5m'
      WALLUST_COLOR6=$'\033[38;5;6m'
      WALLUST_COLOR7=$'\033[38;5;7m'

      WALLUST_COLOR8=$'\033[38;5;8m'
      WALLUST_COLOR9=$'\033[38;5;9m'
      WALLUST_COLOR10=$'\033[38;5;10m'
      WALLUST_COLOR11=$'\033[38;5;11m'
      WALLUST_COLOR12=$'\033[38;5;12m'
      WALLUST_COLOR13=$'\033[38;5;13m'
      WALLUST_COLOR14=$'\033[38;5;14m'
      WALLUST_COLOR15=$'\033[38;5;15m'

      export WALLUST_COLOR{0..15}
    '';
  };
}
