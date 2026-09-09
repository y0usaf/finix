{
  lib,
  pkgs,
  ...
}: let
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "hermes-project";
    version = "0.1.0";
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [./project_runner.py ./test_project_runner.py];
    };
    nativeBuildInputs = [pkgs.makeWrapper pkgs.python3 pkgs.git];
    dontBuild = true;
    doCheck = true;
    checkPhase = ''
      python3 -m unittest -v test_project_runner.py
    '';
    installPhase = ''
      install -Dm644 project_runner.py $out/lib/hermes-project/project_runner.py
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/hermes-project \
        --add-flags "$out/lib/hermes-project/project_runner.py" \
        --prefix PATH : ${lib.makeBinPath [pkgs.git]}
    '';
    meta = {
      description = "Bounded, restartable planner/worker projects for Hermes";
      mainProgram = "hermes-project";
      platforms = lib.platforms.linux;
    };
  };
in {
  options.user.dev.hermes.projectRunner = lib.mkOption {
    type = lib.types.package;
    default = package;
    description = "Optional project scheduler; uses the active Hermes CLI and profiles.";
  };
}
