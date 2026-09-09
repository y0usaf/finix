{
  lib,
  flakeInputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  ekko = flakeInputs.ekko-zellij-preview;
  previewPkgs = ekko.inputs.nixpkgs.legacyPackages.${system};
  runtime = ekko.packages.${system}.default;
  preview = previewPkgs.writeShellApplication {
    name = "finix-ekko-zellij-preview";
    runtimeInputs = [previewPkgs.coreutils];
    text = ''
      export EKKO_PREVIEW_BINARY=${runtime}/bin/ekko
      export EKKO_PREVIEW_PROFILE=${ekko}/examples/profiles/zellij.lisp
      ${builtins.readFile ./launch.sh}
    '';
  };
in {
  options.user.shell.ekko.zellijPreview = lib.mkOption {
    description = "Disposable Zellij profile preview and runtime.";
    type = lib.types.submodule {
      options = {
        package = lib.mkOption {type = lib.types.package;};
        runtime = lib.mkOption {type = lib.types.package;};
      };
    };
    default = {
      package = preview;
      inherit runtime;
    };
  };
}
