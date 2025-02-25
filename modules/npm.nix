{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  programs.zsh = {
    envExtra = ''
      # NPM environment variables
      export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
    '';
  };
} 