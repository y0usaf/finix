{lib, ...}: let
  roots = [
    ".fx/skills"
    ".pi/agent/skills"
    ".config/phi/skills"
    ".prime/agent/skills"
    ".reasonix/skills"
    ".omp/agent/skills"
  ];

  mkSkill = name: files:
    map (root:
      lib.mapAttrs' (rel: spec: lib.nameValuePair "${root}/${name}/${rel}" spec)
      files)
    roots;
in {
  config.lib.prompts = {inherit mkSkill;};
}
