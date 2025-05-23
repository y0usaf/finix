###############################################################################
# Secrets Management Module
# SOPS-based secrets management for API keys, tokens, and sensitive data
# - Encrypted secrets stored in repository
# - Decrypted at runtime using age keys
# - Fine-grained permissions and access control
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  sops-nix,
  ...
}: {
  imports = [
    sops-nix.nixosModules.sops
  ];

  config = {
    ###########################################################################
    # SOPS Configuration
    ###########################################################################
    sops = {
      defaultSopsFile = ../../../secrets/api-keys.yaml;
      defaultSopsFormat = "yaml";
      
      age = {
        keyFile = "/home/${hostSystem.cfg.system.username}/.config/sops/age/keys.txt";
        generateKey = true;
      };

      secrets = {
        # AI API Keys
        anthropic_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        openai_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        cohere_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        cohere_staging_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        gemini_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        groq_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        openrouter_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        
        # Cloud Services
        aws_secret_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        hf_token = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        
        # Development Tools
        notion_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        slack_token = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        wandb_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        
        # Other Services
        brave_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        scale_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
        tiingo_api_key = {
          owner = hostSystem.cfg.system.username;
          group = "users";
          mode = "0400";
        };
      };
    };

    ###########################################################################
    # System Packages
    ###########################################################################
    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    ###########################################################################
    # Environment Variables for Development
    # These will be available system-wide
    ###########################################################################
    environment.variables = {
      # Create a script that sources all API keys
      SECRETS_DIR = "/run/secrets";
    };

    ###########################################################################
    # User Environment Setup
    # Create a script to easily source secrets in shell sessions
    ###########################################################################
    environment.etc."secrets-env.sh" = {
      text = ''
        #!/bin/bash
        # Source this file to load all API keys into your environment
        # Usage: source /etc/secrets-env.sh
        
        export ANTHROPIC_API_KEY="$(cat /run/secrets/anthropic_api_key 2>/dev/null || echo "")"
        export OPENAI_API_KEY="$(cat /run/secrets/openai_api_key 2>/dev/null || echo "")"
        export COHERE_API_KEY="$(cat /run/secrets/cohere_api_key 2>/dev/null || echo "")"
        export COHERE_STAGING_API_KEY="$(cat /run/secrets/cohere_staging_api_key 2>/dev/null || echo "")"
        export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key 2>/dev/null || echo "")"
        export GROQ_API_KEY="$(cat /run/secrets/groq_api_key 2>/dev/null || echo "")"
        export OPENROUTER_API_KEY="$(cat /run/secrets/openrouter_api_key 2>/dev/null || echo "")"
        export AWS_SECRET_KEY="$(cat /run/secrets/aws_secret_key 2>/dev/null || echo "")"
        export HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || echo "")"
        export NOTION_KEY="$(cat /run/secrets/notion_key 2>/dev/null || echo "")"
        export SLACK_TOKEN="$(cat /run/secrets/slack_token 2>/dev/null || echo "")"
        export WANDB_API_KEY="$(cat /run/secrets/wandb_api_key 2>/dev/null || echo "")"
        export BRAVE_API_KEY="$(cat /run/secrets/brave_api_key 2>/dev/null || echo "")"
        export SCALE_API_KEY="$(cat /run/secrets/scale_api_key 2>/dev/null || echo "")"
        export TIINGO_API_KEY="$(cat /run/secrets/tiingo_api_key 2>/dev/null || echo "")"
        
        echo "🔑 Secrets loaded into environment variables"
      '';
      mode = "0755";
    };
  };
}