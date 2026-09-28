{
  lib,
  pkgs,
}: let
  indent = rules: lib.concatMapStringsSep "\n" (line: lib.optionalString (line != "") "    ${line}") (lib.splitString "\n" rules);
in {
  btrfs = uuid: options: subvol: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = [subvol] ++ options;
    neededForBoot = true;
  };

  nftables = name: {
    tailscaleComment ? null,
    input,
    forward ? "",
  }:
    pkgs.writeText name ''
      flush ruleset

      table inet filter {
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
      }
    '';
}
