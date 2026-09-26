{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.autolith;

  inherit (config.user.dev.prompts) ethics noTests noComments;

  # Render VALUE as a Common Lisp string literal. Newlines are legal inside CL
  # string literals, so only backslash and double-quote need escaping.
  lispString = value:
    "\"" + lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] value + "\"";

  # Ethics is registered first and given the lower priority so it precedes the
  # no-test policy inside the same request-local context (context--render sorts
  # ascending by priority, src/agent/context.lisp).
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

  # The policy contributors are always present; user-supplied initLisp content
  # is appended verbatim after them and loads in the same image.
  initLisp =
    ethicsLisp
    + "\n"
    + policyLisp
    + (lib.optionalString (cfg.initLisp != "") ("\n" + cfg.initLisp));
in {
  options.user.dev.autolith = {
    enable = lib.mkEnableOption "Autolith live Common Lisp AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakeInputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "Autolith package, including its matching Lisp runtime.";
    };

    initLisp = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra Common Lisp appended to ~/.config/autolith/init.lisp, after the
        built-in policy contributors. The file is always managed now: the shared
        policies (config.user.dev.prompts.ethics and
        config.user.dev.prompts.noTests and noComments) are registered first and this content
        loads after them in the same image.
        Keep credentials out of this option; authenticate with `autolith auth`
        instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    manzil.users.${config.user.name}.files.".config/autolith/init.lisp".text = initLisp;

    # Preserve auth/preferences, conversations/private images, and recovery
    # state across home resets. The XDG cache is disposable.
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
  };
}
