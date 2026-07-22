{config, ...}: {
  # authorizedKeys come from modules/core/services/openssh.nix (all hosts).
  users.users."${config.user.name}".hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
}
