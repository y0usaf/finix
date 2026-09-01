# Library, not a module (excluded from the recursive walk like
# kimi-code/package.nix). Owns the one question "where do skill files
# belong": every enabled agent harness's skills dir. Skills declare only
# their name + file map; adding a harness (claude/codex) is a one-line
# change here instead of per-skill.
{
  config,
  lib,
}: let
  roots =
    (lib.optional config.user.dev.fx.enable ".fx/skills")
    ++ (lib.optional config.user.dev.pi.enable ".pi/agent/skills")
    # phi has no per-user skills dir of its own; it scans ~/.config/phi/skills.
    ++ (lib.optional config.user.dev.phi.enable ".config/phi/skills")
    ++ (lib.optional config.user.dev.prime-agent.enable ".prime/agent/skills")
    ++ (lib.optional config.user.dev.reasonix.enable ".reasonix/skills")
    # oh-my-pi discovers user skills at ~/.omp/agent/skills (same layout as
    # pi's ~/.pi/agent/skills; managed-skills is a separate omp-owned dir).
    ++ (lib.optional config.user.dev.omp.enable ".omp/agent/skills");

  # mkSkill name files -> list of per-root attrsets, ready for lib.mkMerge.
  # files: relative path -> manzil file spec ({text}|{source}|{text,executable}).
  mkSkill = name: files:
    map (root:
      lib.mapAttrs' (rel: spec: lib.nameValuePair "${root}/${name}/${rel}" spec)
      files)
    roots;
in {
  inherit roots mkSkill;
}
