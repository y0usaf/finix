{
  lib,
  pkgs,
  ...
}: let
  vercel = pkgs.writeScriptBin "vercel" ''
    #!${pkgs.python3}/bin/python3
    import json, sys
    print(json.dumps(sys.argv[1:]))
  '';
  wrapper =
    (lib.evalModules {
      specialArgs = {inherit pkgs;};
      modules = [
        ./wrapper.nix
        {
          user.dev.work.vercel = {
            package = vercel;
            workOwners = ["work-org"];
          };
        }
      ];
    }).config.user.dev.work.vercel.wrappedPackage;
in {
  options.user.dev.work.vercel.routingCheck = lib.mkOption {
    type = lib.types.package;
    description = "Account-routing regression check using the Vercel module.";
    default =
      pkgs.runCommand "vercel-account-routing-tests" {
        nativeBuildInputs = [wrapper pkgs.git pkgs.python3];
      } ''
        python3 ${./tests.py}
        touch $out
      '';
  };
}
