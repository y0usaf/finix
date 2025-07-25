{
  config,
  lib,
  ...
}: let
  cfg = config.home.shell.cat-fetch;
in {
  options.home.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid.file.home.".config/zsh/.zshrc".text = lib.mkAfter ''
      print_cats() {
          echo -e "\033[0;31m ⟋|､      \033[0;34m  ⟋|､      \033[0;35m  ⟋|､      \033[0;32m  ⟋|､
      \033[0;31m(°､ ｡ 7    \033[0;34m(°､ ｡ 7    \033[0;35m(°､ ｡ 7    \033[0;32m(°､ ｡ 7
      \033[0;31m |､  ~ヽ   \033[0;34m |､  ~ヽ   \033[0;35m |､  ~ヽ   \033[0;32m |､  ~ヽ
      \033[0;31m じしf_,)〳\033[0;34m じしf_,)〳\033[0;35m じしf_,)〳\033[0;32m じしf_,)〳
      \033[0;36m  [tomo]   \033[0;33m  [moon]   \033[0;32m  [ekko]   \033[0;35m  [bozo]\033[0m"
      }
      print_cats
    '';
  };
}
