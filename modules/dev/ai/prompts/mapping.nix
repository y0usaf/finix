# Shared module library: map skill files into every enabled agent harness's
# skills dir. Skills declare only their name + file map; adding a harness
# (claude/codex) is a one-line change here instead of per-skill.
{
  config,
  lib,
  ...
}: let
  roots = map (entry: entry.root) (lib.filter (entry: entry.enabled) [
    {
      enabled = config.user.dev.fx.enable;
      root = ".fx/skills";
    }
    {
      enabled = config.user.dev.pi.enable;
      root = ".pi/agent/skills";
    }
    # phi has no per-user skills dir of its own; it scans ~/.config/phi/skills.
    {
      enabled = config.user.dev.phi.enable;
      root = ".config/phi/skills";
    }
    {
      enabled = config.user.dev.prime-agent.enable;
      root = ".prime/agent/skills";
    }
    {
      enabled = config.user.dev.reasonix.enable;
      root = ".reasonix/skills";
    }
    # oh-my-pi discovers user skills at ~/.omp/agent/skills (same layout as
    # pi's ~/.pi/agent/skills; managed-skills is a separate omp-owned dir).
    {
      enabled = config.user.dev.omp.enable;
      root = ".omp/agent/skills";
    }
  ]);

  # mkSkill name files -> list of per-root attrsets, ready for lib.mkMerge.
  # files: relative path -> manzil file spec ({text}|{source}|{text,executable}).
  mkSkill = name: files:
    map (root:
      lib.mapAttrs' (rel: spec: lib.nameValuePair "${root}/${name}/${rel}" spec)
      files)
    roots;
in {
  config.lib.prompts = {inherit roots mkSkill;};
}
