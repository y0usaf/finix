{lib, ...}: let
  indent = rules: lib.concatMapStringsSep "\n" (line: lib.optionalString (line != "") "    ${line}") (lib.splitString "\n" rules);
in {
  btrfs = uuid: options: subvol: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = [subvol] ++ options;
    neededForBoot = true;
  };

  bashFiles = {interactive ? ""}: {
    ".bashrc".text =
      ''
        case $- in
          *i*) ;;
          *) return ;;
        esac

      ''
      + interactive
      + ''
        HISTSIZE=10000
        HISTFILESIZE=10000
        HISTCONTROL=ignoreboth:erasedups
        shopt -s histappend checkwinsize

        alias la="ls -a"
        alias ll="ls -l"
        alias lla="ls -la"
      '';
    ".bash_profile".text = ''
      [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
    '';
  };

  filterTable = {
    tailscaleComment ? null,
    input,
    forward ? "",
  }: ''
      chain input {
        type filter hook input priority filter; policy drop;

        iifname "lo" accept
        iifname "tailscale0" accept${lib.optionalString (tailscaleComment != null) " comment \"${tailscaleComment}\""}
        ct state established,related accept
        ct state invalid drop
        meta l4proto { icmp, ipv6-icmp } accept

    ${indent input}  }
    ${lib.optionalString (forward != "") "\n"}  chain forward {
        type filter hook forward priority filter; policy drop;
    ${indent forward}  }
  '';
}
