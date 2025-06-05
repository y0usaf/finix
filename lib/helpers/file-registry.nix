###############################################################################
# Universal File Registry System
# Simple primitives: declare files, add content, auto-build
###############################################################################
{lib, ...}: rec {
  
  #=============================================================================
  # Global Registry Options
  #=============================================================================
  mkFileRegistryOptions = {
    # Declare files: "name" = "path" or "name" = { filename = "path"; baseContent = "..."; }
    fileRegistry.declare = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.submodule {
        options = {
          filename = lib.mkOption {
            type = lib.types.str;
            description = "File path";
          };
          baseContent = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Base file content";
          };
        };
      }));
      default = {};
      description = "Declare files that can receive content";
      example = {
        zshrc = ".zshrc";
        gitconfig = { filename = ".gitconfig"; baseContent = "[core]\n  editor = nvim"; };
      };
    };
    
    # Add content: fileRegistry.content.filename.section = "content"
    fileRegistry.content = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.lines);
      default = {};
      description = "Add content sections to declared files";
      example = {
        zshrc.aliases = "alias ll='ls -la'";
        gitconfig.user = "[user]\n  name = John";
      };
    };
  };
  
  #=============================================================================
  # Auto-builder: Build all declared files with their content
  #=============================================================================
  buildRegisteredFiles = { declarations, content, username }: let
    # Normalize declarations to { filename, baseContent }
    normalize = name: decl: 
      if lib.isString decl 
      then { filename = decl; baseContent = ""; }
      else decl;
    
    normalizedDecls = lib.mapAttrs normalize declarations;
    
    # Build each file
    buildFile = name: decl: let
      sections = lib.attrValues (content.${name} or {});
      allContent = [decl.baseContent] ++ sections;
      validContent = lib.filter (s: s != "" && s != null) allContent;
      finalContent = lib.concatStringsSep "\n\n" validContent;
    in lib.optionalAttrs (finalContent != "") {
      ${decl.filename}.text = finalContent;
    };
    
    allFiles = lib.mapAttrsToList buildFile normalizedDecls;
  in {
    files = lib.mkMerge allFiles;
  };
}