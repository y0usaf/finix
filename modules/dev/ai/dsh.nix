{
  pkgs,
  inputPackages,
  ...
}: let
  inherit (inputPackages.deepseek-harness-flake) dsh;
  inherit (inputPackages.dsh-tern) default;
in {
  environment.systemPackages = [dsh default];

  user.persist.directories = [".local/state/dsh"];
}
