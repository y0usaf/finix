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
    (define-context-contributor shared-policy (request)
      "Deliver the instructions every harness shares with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "shared-policy"
       :instruction "${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] config.user.dev.prompts.shared}"
       :priority 39
       :class :mandatory))
  '';

  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/autolith"
    ".local/share/autolith"
    ".local/state/autolith"
  ];
}
