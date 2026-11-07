{lib, ...}: let
  indent = rules: lib.concatMapStringsSep "\n" (line: lib.optionalString (line != "") "    ${line}") (lib.splitString "\n" rules);
in {
  btrfs = uuid: options: subvol: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = [subvol] ++ options;
    neededForBoot = true;
  };

  fileSystems = {
    rootSize,
    tmpSize ? null,
    boot,
    mounts,
  }:
    {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = ["mode=755" "size=${rootSize}"];
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/${boot.uuid}";
        fsType = "vfat";
        inherit (boot) options;
        neededForBoot = true;
      };
    }
    // lib.optionalAttrs (tmpSize != null) {
      "/tmp" = {
        device = "none";
        fsType = "tmpfs";
        options = ["mode=1777" "size=${tmpSize}" "nosuid" "nodev" "strictatime"];
        neededForBoot = true;
      };
    }
    // mounts;

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

  bolo = {
    model = {
      name = "parakeet-v3-int8";
      engine = "sherpa-onnx-transducer";
      url = "https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main";
      hashes = {
        "encoder.int8.onnx" = "sha256-rPwrRFY3fhXQTwJDr1QLf+fJkvjYmNdRzxNMOlX9Ikc=";
        "decoder.int8.onnx" = "sha256-F55QxD0aneeciiQUmi+brG61mBgj8qLtiNZVskJI204=";
        "joiner.int8.onnx" = "sha256-MWTBP8KCEAlEDSD8tf3Hi/8otNsvjQ8LMpEBcZwJSLM=";
        "tokens.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
      };
    };
    vocabulary = {
      Hyprland = ["hyper land" "hipper land"];
      niri = ["neary" "nyree"];
      y0usaf = ["you sef" "yousef" "you saf"];
      "sherpa-onnx" = ["sherpa onyx" "sherpa onix"];
      tomoe = ["toe moe" "tomo eh"];
      ekko = ["eck oh" "eh ko"];
      moon = [];
      finix = ["fee nix" "finnix" "fi nix"];
    };
  };
}
