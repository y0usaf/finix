{config, ...}: {
  config = {
    security.sudo.extraRules = [
      {
        users = [config.hostSystem.username];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
