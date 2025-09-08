{hostConfig, ...}: {
  config = {
    security.sudo.extraRules = [
      {
        users = ["y0usaf"];
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
