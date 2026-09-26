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
    {
      enabled = config.user.dev.omp.enable;
      root = ".omp/agent/skills";
    }
  ]);

  mkSkill = name: files:
    map (root:
      lib.mapAttrs' (rel: spec: lib.nameValuePair "${root}/${name}/${rel}" spec)
      files)
    roots;
in {
  config.lib.prompts = {inherit roots mkSkill;};
}
