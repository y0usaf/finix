{
  config,
  flakeDirectory,
}:
(import ../../../../lib/shell/zsh/common-aliases.nix {})
// (import ../../../../lib/shell/zsh/nixos-aliases.nix {})
// {
  buildtime = "time (nix build \${NH_FLAKE}#nixosConfigurations.\${HOST}.config.system.build.toplevel --option eval-cache false)";

  hmpush = "git -C ${flakeDirectory} push origin main --force";
  hmpull = "git -C ${flakeDirectory} fetch origin && git -C ${flakeDirectory} reset --hard origin/main";
}
// (
  if config.hardware.nvidia.enable
  then {
    nvidia-settings = ''nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'';
    gpupower = "sudo nvidia-smi -pl";
  }
  else {}
)
