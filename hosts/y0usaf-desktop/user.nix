{config, ...}: {
  users.users."${config.user.name}".hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
  users.users.root.hashedPasswordFile = "/persist/secrets/password-hashes/root";
}
