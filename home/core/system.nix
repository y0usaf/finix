###############################################################################
# Home Manager Core Configuration
# Configures Home Manager's core settings based on shared configuration
###############################################################################
{
  config,
  ...
}: {
  # Configure Home Manager core settings from shared configuration
  config.home = {
    inherit (config.cfg.shared) username homeDirectory stateVersion;
    enableNixpkgsReleaseCheck = false;
  };
}
