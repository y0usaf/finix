{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  autolith = flakeInputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default;

  inherit (config.user.dev.prompts) ethics noTests noComments;

  lispString = value:
    "\"" + lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] value + "\"";

  ethicsLisp = ''
    (define-context-contributor ethics-policy (request)
      "Deliver the shared compaction/ethics instructions with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "ethics-policy"
       :instruction ${lispString ethics}
       :priority 39
       :class :mandatory))
  '';

  policyLisp = ''
    (define-context-contributor code-policy (request)
      "Deliver the shared no-test and no-comment policies with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "code-policy"
       :instruction ${lispString (noTests + "\n\n" + noComments)}
       :priority 40
       :class :mandatory))
  '';
in {
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "autolith-full-access";
      paths = [autolith];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/autolith" --add-flags "--permissions full"
      '';
      meta = autolith.meta // {mainProgram = "autolith";};
    })
  ];

  manzil.users.${config.user.name}.files.".config/autolith/init.lisp".text = ethicsLisp + "\n" + policyLisp;

  finix.persistence.allowlist.users.${config.user.name}.directories =
    map
    (directory: {
      inherit directory;
      mode = "0700";
    })
    [
      ".config/autolith"
      ".local/share/autolith"
      ".local/state/autolith"
    ];
}
