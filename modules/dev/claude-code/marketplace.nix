{
  config,
  lib,
  ...
}: let
  inherit (config) user;
  claudeCodeCfg = user.dev.claude-code;
in {
  config = lib.mkIf claudeCodeCfg.enable {
    manzil.users."${user.name}".files =
      (let
        inherit (builtins) toJSON;
        inherit (lib) foldl' optionalAttrs mapAttrs mapAttrs' mapAttrsToList nameValuePair attrNames;
      in {
        # Main build function
        build = {
          basePath ? ".config/claude",
          description ? "Personal Claude Code plugin marketplace",
          name,
          owner,
          plugins,
          version ? "1.0.0",
        }:
        # Marketplace manifest
          {
            "${basePath}/.claude-plugin/marketplace.json" = {
              text = ({
                description ? "Personal Claude Code plugin marketplace",
                name,
                owner,
                plugins,
                version ? "1.0.0",
              }:
                toJSON {
                  inherit name version;
                  metadata = {
                    inherit description;
                    pluginRoot = "./plugins";
                  };
                  owner = {
                    inherit (owner) name;
                    email = owner.email or "";
                  };
                  plugins =
                    mapAttrsToList (pluginName: plugin: {
                      name = pluginName;
                      source = "./plugins/${pluginName}";
                      inherit (plugin) description version;
                      author = plugin.author or owner;
                      strict = false; # marketplace entry serves as manifest
                    })
                    plugins;
                }) {inherit name owner plugins description version;};
            };
          }
          # All plugin files
          // foldl' (acc: pluginName:
            acc
            // (basePath: pluginName: plugin: let
              pluginPath = "${basePath}/plugins/${pluginName}";
              pluginHooks = plugin.hooks;
            in
              # plugin.json
              {
                "${pluginPath}/.claude-plugin/plugin.json" = {
                  text =
                    (name: plugin:
                      toJSON (
                        {
                          inherit name;
                          inherit (plugin) description version;
                          author = plugin.author or {};
                        }
                        // optionalAttrs (plugin ? hooks) {
                          hooks = "./hooks/hooks.json";
                        }
                        // optionalAttrs (plugin ? mcpServers) {
                          inherit (plugin) mcpServers;
                        }
                      ))
                    pluginName
                    plugin;
                };
              }
              # Commands
              // optionalAttrs (plugin ? commands) (
                mapAttrs' (cmdName: cmdContent:
                  nameValuePair "${pluginPath}/commands/${cmdName}.md" {
                    text = cmdContent;
                  })
                plugin.commands
              )
              # Hooks configuration
              // optionalAttrs (plugin ? hooks && pluginHooks != {}) {
                "${pluginPath}/hooks/hooks.json" = {
                  text = (hooks:
                    toJSON {
                      hooks =
                        mapAttrs (
                          _: eventHooks:
                            map (hook: {
                              inherit (hook) matcher;
                              hooks =
                                map (h: {
                                  type = h.type or "command";
                                  inherit (h) command;
                                })
                                hook.hooks;
                            })
                            eventHooks
                        )
                        hooks;
                    })
                  pluginHooks.config;
                };
              }
              # Hook scripts
              // optionalAttrs (plugin ? hooks.scripts) (
                mapAttrs' (scriptName: scriptContent:
                  nameValuePair "${pluginPath}/hooks/scripts/${scriptName}" {
                    text = scriptContent;
                    executable = true;
                  })
                pluginHooks.scripts
              )
              # Instructions (CLAUDE.md at plugin root)
              // optionalAttrs (plugin ? instructions) {
                "${pluginPath}/CLAUDE.md" = {
                  text = plugin.instructions;
                };
              }
              # Agents
              // optionalAttrs (plugin ? agents) (
                mapAttrs' (agentName: agentContent:
                  nameValuePair "${pluginPath}/agents/${agentName}.md" {
                    text = agentContent;
                  })
                plugin.agents
              )
              # Skills
              // optionalAttrs (plugin ? skills) (
                let
                  pluginSkills = plugin.skills;
                in
                  foldl' (
                    acc: skillName: let
                      skill = pluginSkills."${skillName}";
                      inherit (builtins) isAttrs;
                    in
                      acc
                      // {
                        "${pluginPath}/skills/${skillName}/SKILL.md" = {
                          text =
                            if isAttrs skill
                            then skill.skill
                            else skill;
                        };
                      }
                      // optionalAttrs (isAttrs skill && skill ? interface) {
                        "${pluginPath}/skills/${skillName}/agents/openai.yaml" = {
                          generator = lib.generators.toYAML {};
                          value = {
                            inherit (skill) interface;
                          };
                        };
                      }
                  ) {} (attrNames pluginSkills)
              )
              # Data files (arbitrary files at plugin root)
              // optionalAttrs (plugin ? dataFiles) (
                mapAttrs' (fileName: fileContent:
                  nameValuePair "${pluginPath}/${fileName}" {
                    text = fileContent;
                  })
                plugin.dataFiles
              ))
            basePath
            pluginName
            plugins."${pluginName}")
          {} (attrNames plugins);
      }).build {
        name = "y0usaf-marketplace";
        owner = {
          name = "y0usaf";
          email = "";
        };
        inherit (claudeCodeCfg) plugins;
        basePath = ".config/claude";
        description = "Personal Claude Code plugin marketplace";
        version = "1.0.0";
      };
  };
}
