{
  lib,
  config,
  flakeDirectory,
}:
(import ../../../../lib/shell/nushell/common-aliases.nix {})
+ (import ../../../../lib/shell/nushell/nixos-aliases.nix {})
+ ''

  # NixOS build timing
  def buildtime [] { timeit { ^nix build $"($env.NH_FLAKE)#nixosConfigurations.($env.HOST).config.system.build.toplevel" --option eval-cache false } }

  # Git helpers for flake repo
  def hmpush [] { ^git -C ${flakeDirectory} push origin main --force }
  def hmpull [] { ^git -C ${flakeDirectory} fetch origin; ^git -C ${flakeDirectory} reset --hard origin/main }
''
+ lib.optionalString config.hardware.nvidia.enable ''

  # Nvidia
  def nvidia-settings [...args: string] { ^nvidia-settings $"--config=($env.XDG_CONFIG_HOME)/nvidia/settings" ...$args }
  def gpupower [watts: string] { sudo nvidia-smi -pl $watts }
''
