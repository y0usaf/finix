{
  config,
  nixosConfigDirectory,
}: let
  commonAliases = import ../../../../lib/shell/zsh/common-aliases.nix {};
  nixosAliases = import ../../../../lib/shell/zsh/nixos-aliases.nix {};
in
commonAliases
// nixosAliases
// {
  buildtime = "time (nix build \${NH_FLAKE}#nixosConfigurations.\${HOST}.config.system.build.toplevel --option eval-cache false)";

  hmpush = "git -C ${nixosConfigDirectory} push origin main --force";
  hmpull = "git -C ${nixosConfigDirectory} fetch origin && git -C ${nixosConfigDirectory} reset --hard origin/main";
}
// (
  if config.hardware.nvidia.enable
  then {
    nvidia-settings = ''nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'';
    gpupower = "sudo nvidia-smi -pl";
  }
  else {}
)
