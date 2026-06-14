{config, ...}: {
  users.users."${config.user.name}".extraGroups = [
    "video"
    "audio"
    "input"
    "dialout"
    "bluetooth"
    "lp"
  ];
}
