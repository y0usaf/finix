{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  dsh = flakeInputs.deepseek-harness-flake.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
  dshTsp = flakeInputs.dsh-tsp.packages.${pkgs.stdenv.hostPlatform.system}.dsh-tsp;
in {
  environment.systemPackages = [dsh dshTsp];

  user.persist.directories = [".dsh"];

  user.files.".config/tern/plugins/dsh.path".text = "${dshTsp}/share/tern/plugins/dsh\n";
}
