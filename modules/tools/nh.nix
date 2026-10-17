{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  environment = {
    systemPackages = [
      flakeInputs.nh.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
    variables.NH_FLAKE = "${config.user.homeDirectory}/finix";
  };
  user.shell.rcExtra = lib.mkAfter ''
    nhs() {
      clear
      local update=""
      local dry=""
      local nix=""
      while [ $# -gt 0 ]; do
        case $1 in
          -d|--dry) dry="--dry" ;;
          -u|--update) update="--update" ;;
          -du|-ud) dry="--dry"; update="--update" ;;
          --nix) nix=1 ;;
          *) break ;;
        esac
        shift
      done
      if [ -n "$nix" ]; then
        GC_DONT_GC=1 nh os switch $update $dry "$@"
        return
      fi
      if [ -n "$update" ]; then
        nix flake update --flake "$NH_FLAKE" || return
      fi
      local out="$XDG_RUNTIME_DIR/nhs-system"
      rm -f "$out"
      if ! iets build -o "$out" "$NH_FLAKE#nixosConfigurations.$(hostname).config.system.build.toplevel"; then
        echo "nhs: iets failed; 'nhs --nix' evaluates with nix instead" >&2
        return 1
      fi
      nh os switch $dry "$@" "$out"
      local rc=$?
      rm -f "$out"
      return $rc
    }
    alias nhd="nhs -d"
    alias nhu="nhs -u"
    alias nhud="nhs -ud"
    alias nhc="nh clean all"
  '';
}
