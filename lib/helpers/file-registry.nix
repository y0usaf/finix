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
        zshrc.early.zellij = "eval \"$(zellij setup --generate-auto-start zsh)\"";
        gitconfig.user = "[user]\n  name = John";
      };
    };
    
    # Add early content: fileRegistry.early.filename.section = "content" (placed before baseContent)
    fileRegistry.early = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.lines);
      default = {};
      description = "Add early content sections (placed before base content)";
      example = {
        zshrc.zellij = "eval \"$(zellij setup --generate-auto-start zsh)\"";
      };
    };
    
    # Add late content: fileRegistry.late.filename.section = "content" (placed after regular content)
    fileRegistry.late = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.lines);
      default = {};
      description = "Add late content sections (placed after regular content)";
      example = {
        zshrc.cleanup = "# Cleanup code";
      };
    };
  };
  
  #=============================================================================
  # Auto-builder: Build all declared files with their content
  # Order: early sections → base content → regular sections → late sections
  #=============================================================================
  buildRegisteredFiles = { declarations, content, early ? {}, late ? {}, username }: let
    # Normalize declarations to { filename, baseContent }
    normalize = name: decl: 
      if lib.isString decl 
      then { filename = decl; baseContent = ""; }
      else decl;
    
    normalizedDecls = lib.mapAttrs normalize declarations;
    
    # Build each file with proper ordering
    buildFile = name: decl: let
      earlySections = lib.attrValues (early.${name} or {});
      regularSections = lib.attrValues (content.${name} or {});
      lateSections = lib.attrValues (late.${name} or {});
      
      # Order: early → base → regular → late
      allContent = earlySections ++ [decl.baseContent] ++ regularSections ++ lateSections;
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