{config, ...}: {
  users.users."${config.user.name}".hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
}
