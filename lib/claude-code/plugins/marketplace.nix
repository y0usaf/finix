# Marketplace builder - generates hjem file entries for Claude Code plugin marketplace
#
# Usage:
#   marketplace.build {
#     name = "y0usaf-marketplace";
#     owner = { name = "y0usaf"; email = "..."; };
#     plugins = import ./default.nix;
#     basePath = ".config/claude";  # where marketplace lives
#   }
#
# Returns: attrset suitable for `usr.files = { ... }`
{lib}: let
  # Generate marketplace.json content
  # Generate plugin.json content
  # Generate hooks.json for a plugin's hooks
  # Format: { "hooks": { "EventName": [{ "matcher": "", "hooks": [...] }], ... } }
  # Build file entries for a single plugin
in {
  # Main build function
  build = {
    name,
    owner,
    plugins,
    basePath ? ".config/claude",
    description ? "Personal Claude Code plugin marketplace",
    version ? "1.0.0",
  }:
  # Marketplace manifest
    {
      "${basePath}/.claude-plugin/marketplace.json" = {
        text = ({
          name,
          owner,
          plugins,
          description ? "Personal Claude Code plugin marketplace",
          version ? "1.0.0",
        }:
          builtins.toJSON {
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
              lib.mapAttrsToList (pluginName: plugin: {
                name = pluginName;
                source = "./plugins/${pluginName}";
                inherit (plugin) description version;
                author = plugin.author or owner;
                strict = false; # marketplace entry serves as manifest
              })
              plugins;
          }) {inherit name owner plugins description version;};
        clobber = true;
      };
    }
    # All plugin files
    // lib.foldl' (acc: pluginName:
      acc
      // (basePath: pluginName: plugin: let
        pluginPath = "${basePath}/plugins/${pluginName}";
      in
        # plugin.json
        {
          "${pluginPath}/.claude-plugin/plugin.json" = {
            text =
              (name: plugin:
                builtins.toJSON (
                  {
                    inherit name;
                    inherit (plugin) description version;
                    author = plugin.author or {};
                  }
                  // lib.optionalAttrs (plugin ? hooks) {
                    hooks = "./hooks/hooks.json";
                  }
                  // lib.optionalAttrs (plugin ? mcpServers) {
                    inherit (plugin) mcpServers;
                  }
                ))
              pluginName
              plugin;
            clobber = true;
          };
        }
        # Commands
        // lib.optionalAttrs (plugin ? commands) (
          lib.mapAttrs' (cmdName: cmdContent:
            lib.nameValuePair "${pluginPath}/commands/${cmdName}.md" {
              text = cmdContent;
              clobber = true;
            })
          plugin.commands
        )
        # Hooks configuration
        // lib.optionalAttrs (plugin ? hooks && plugin.hooks != {}) {
          "${pluginPath}/hooks/hooks.json" = {
            text = (hooks:
              builtins.toJSON {
                hooks =
                  lib.mapAttrs (
                    _event: eventHooks:
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
            plugin.hooks.config;
            clobber = true;
          };
        }
        # Hook scripts
        // lib.optionalAttrs (plugin ? hooks.scripts) (
          lib.mapAttrs' (scriptName: scriptContent:
            lib.nameValuePair "${pluginPath}/hooks/scripts/${scriptName}" {
              text = scriptContent;
              executable = true;
              clobber = true;
            })
          plugin.hooks.scripts
        )
        # Instructions (CLAUDE.md at plugin root)
        // lib.optionalAttrs (plugin ? instructions) {
          "${pluginPath}/CLAUDE.md" = {
            text = plugin.instructions;
            clobber = true;
          };
        }
        # Agents
        // lib.optionalAttrs (plugin ? agents) (
          lib.mapAttrs' (agentName: agentContent:
            lib.nameValuePair "${pluginPath}/agents/${agentName}.md" {
              text = agentContent;
              clobber = true;
            })
          plugin.agents
        )
        # Skills
        // lib.optionalAttrs (plugin ? skills) (
          lib.foldl' (
            acc: skillName: let
              skill = plugin.skills.${skillName};
            in
              acc
              // {
                "${pluginPath}/skills/${skillName}/SKILL.md" = {
                  text =
                    if builtins.isAttrs skill
                    then skill.skill
                    else skill;
                  clobber = true;
                };
              }
              // lib.optionalAttrs (builtins.isAttrs skill && skill ? interface) {
                "${pluginPath}/skills/${skillName}/agents/openai.yaml" = {
                  generator = lib.generators.toYAML {};
                  value = {
                    inherit (skill) interface;
                  };
                  clobber = true;
                };
              }
          ) {} (lib.attrNames plugin.skills)
        )
        # Data files (arbitrary files at plugin root)
        // lib.optionalAttrs (plugin ? dataFiles) (
          lib.mapAttrs' (fileName: fileContent:
            lib.nameValuePair "${pluginPath}/${fileName}" {
              text = fileContent;
              clobber = true;
            })
          plugin.dataFiles
        ))
      basePath
      pluginName
      plugins.${pluginName})
    {} (lib.attrNames plugins);
}
