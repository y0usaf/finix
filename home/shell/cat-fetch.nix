#===============================================================================
# 🐱 Cat Fetch Display Module for Maid 🐱
# Provides colorful cat display functionality for shell startup
#===============================================================================
{
  config,
  lib,
  ...
}: let
  cfg = config.home.shell.cat-fetch;
in {
  #===========================================================================
  # Module Options
  #===========================================================================
  options.home.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };

  #===========================================================================
  # Module Configuration
  #===========================================================================
  config = lib.mkIf cfg.enable {
    # Add cat fetch function to zsh startup
    users.users.y0usaf.maid.file.home.".zshrc".text = lib.mkAfter ''
      # ----------------------------
      # Function: print_cats
      # ----------------------------
      # Prints a colorful array of cats to the terminal using template approach.
      print_cats() {
          local colors=("0;31" "0;34" "0;35" "0;32")  # red blue magenta green
          local bracket_colors=("0;36" "0;33" "0;32" "0;35")  # cyan yellow green magenta
          local names=("tomo" "moon" "ekko" "bozo")
          
          declare -a lines
          lines[0]=""
          lines[1]=""
          lines[2]=""
          lines[3]=""
          lines[4]=""
          
          for i in {0..3}; do
              local color="$${colors[$$i]}"
              local bracket_color="$${bracket_colors[$$i]}"
              local name="$${names[$$i]}"
              
              lines[0]+=" \033[$${color}m ⟋|､      "
              lines[1]+="\033[$${color}m(°､ ｡ 7    "
              lines[2]+="\033[$${color}m |､  ~ヽ   "
              lines[3]+="\033[$${color}m じしf_,)〳"
              lines[4]+="\033[$${bracket_color}m  [$${name}]   "
          done
          
          printf "%s\n%s\n%s\n%s\n%s\033[0m\n" "$${lines[0]}" "$${lines[1]}" "$${lines[2]}" "$${lines[3]}" "$${lines[4]}"
      }

      # Immediately print the cats on startup.
      print_cats
    '';
  };
}