{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: {
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "autolith-full-access";
      paths = [inputPackages.autolith.default];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/autolith" --add-flags "--permissions full"
      '';
      meta = inputPackages.autolith.default.meta // {mainProgram = "autolith";};
    })
  ];

  user.files.".config/autolith/init.lisp".text = ''
    (define-context-contributor shared-policy (request)
      "Deliver the instructions every harness shares with every provider request."
      (declare (ignore request))
      (make-context-contribution
       :identifier "shared-policy"
       :instruction "${lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] config.user.dev.prompts.shared}"
       :priority 39
       :class :mandatory))
  '';

  user.persist.directories = [
    ".config/autolith"
    ".local/share/autolith"
    ".local/state/autolith"
  ];
}
