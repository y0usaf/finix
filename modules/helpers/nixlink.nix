# modules/helpers/nixlink.nix
# Helper function to generate a home-manager file configuration from content.

# Takes pkgs and lib as arguments
{ pkgs, lib, ... }:

# Returns a function that takes the link parameters
{ content, # String: The content of the file
  path,    # String: The target path relative to $HOME
  enable ? true, # Boolean: Whether to enable this link (default: true)
  # Optional: Allow overriding the derivation name
  drvName ? null,
}:

if !enable then
  # If disabled, return an empty attribute set - effectively doing nothing
  {}
elset
  let
    # Generate a somewhat reasonable name for the derivation in the Nix store.
    # Uses the basename of the target path, sanitized.
    # Example: ".config/foo/bar.conf" -> "bar.conf"
    baseName = lib.strings.sanitizeDerivationName (lib.strings.removeSuffix ".content" (lib.baseNameOf path));

    # Use provided drvName if it exists, otherwise use the generated baseName
    finalDrvName = if drvName != null then drvName else baseName;

    # Write the content to the Nix store
    storePath = pkgs.writeText finalDrvName content;
  in
  {
    # Return the attribute set defining the file copy for home-manager
    home.file."${path}" = {
      source = storePath; # Use the store path as the source for the copy
      # Optional: could add 'executable = true/false;' here if needed
      # Optional: could add 'force = true;' here if needed to overwrite
    };
  }
