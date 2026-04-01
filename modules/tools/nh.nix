{
  config,
  lib,
  pkgs,
  ...
}: let
  nhOpts = config.user.tools.nh;
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
in {
  options.user.tools.nh = {
    enable = lib.mkEnableOption "nh (Nix Helper) shell integration";
    flake = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.singleLineStr lib.types.path);
      default = null;
      description = ''
        The path that will be used for the NH_FLAKE environment variable.
        NH_FLAKE is used by nh as the default flake for performing actions,
        like 'nh os switch'. If not set, nh will look for a flake in the current
        directory or prompt for the flake path.
      '';
    };
  };
  config = lib.mkIf nhOpts.enable {
    environment.systemPackages = [
      pkgs.nh
    ];
    bayt.users."${config.user.name}".files = let
      nhFlake = toString (
        if nhOpts.flake != null
        then nhOpts.flake
        else config.user.paths.flake.path
      );
    in
      lib.optionalAttrs zshEnabled {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            export NH_FLAKE="${nhFlake}"
            nhs() {
              clear
              local update=""
              local dry=""
              local OPTIND
              while getopts "du" opt; do
                case $opt in
                  d) dry="--dry" ;;
                  u) update="--update" ;;
                  *) echo "Invalid option: -$OPTARG" >&2 ;;
                esac
              done
              shift $((OPTIND-1))
              nh os switch $update $dry "$@"
            }
            alias nhd="nhs -d"
            alias nhu="nhs -u"
            alias nhud="nhs -ud"
            alias nhc="nh clean all"
          '';
          clobber = true;
        };
      }
      // lib.optionalAttrs nushellEnabled {
        ".config/nushell/env.nu" = {
          text = lib.mkAfter ''
            $env.NH_FLAKE = "${nhFlake}"
          '';
          clobber = true;
        };
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            def nhs [--dry(-d), --update(-u), ...rest: string] {
              clear
              let update_flag = if $update { ["--update"] } else { [] }
              let dry_flag = if $dry { ["--dry"] } else { [] }
              ^nh os switch ...$update_flag ...$dry_flag ...$rest
            }
            alias nhd = nhs -d
            alias nhu = nhs -u
            alias nhud = nhs -u -d
            alias nhc = nh clean all
          '';
          clobber = true;
        };
      };
  };
}
