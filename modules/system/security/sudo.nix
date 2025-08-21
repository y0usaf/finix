{
  config,
  hostConfig,
  ...
}: {
  config = {
    security.sudo.extraRules = [
      {
        users = [(builtins.head hostConfig.users)];
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
