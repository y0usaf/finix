{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "autolith-full-access";
      paths = [flakeInputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/autolith" --add-flags "--permissions full"
      '';
      meta = flakeInputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default.meta // {mainProgram = "autolith";};
    })
  ];

  manzil.users.${config.user.name}.files.".config/autolith/init.lisp".text = ''
    (define-context-contributor ethics-policy (request)
      "Deliver the shared compaction/ethics instructions with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "ethics-policy"
       :instruction "${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] config.user.dev.prompts.ethics}"
       :priority 39
       :class :mandatory))

    (define-context-contributor code-policy (request)
      "Deliver the shared no-test and no-comment policies with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "code-policy"
       :instruction "${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] (config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments)}"
       :priority 40
       :class :mandatory))
  '';

  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/autolith"
    ".local/share/autolith"
    ".local/state/autolith"
  ];
}
