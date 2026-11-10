{inputPackages, ...}: let
  inherit (inputPackages) dsh-tsp deepseek-harness-flake;
  dshTsp = dsh-tsp.default;
in {
  environment.systemPackages = [deepseek-harness-flake.dsh dshTsp];

  user.persist.directories = [".local/state/dsh"];

  user.files.".config/tern/plugins/dsh.path".text = "${dshTsp}/share/tern/plugins/dsh\n";
}
