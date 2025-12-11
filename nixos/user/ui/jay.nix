{
  pkgs,
  flakeInputs,
  system,
  ...
}: let
  jayWithLibs = pkgs.symlinkJoin {
    name = "jay-wrapped";
    paths = [flakeInputs.jay.packages.${system}.jay];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/jay \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
        pkgs.vulkan-loader
        pkgs.libGL
      ]}
    '';
  };
in {
  environment.systemPackages = [jayWithLibs];
}
