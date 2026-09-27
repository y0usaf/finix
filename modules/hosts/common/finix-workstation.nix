_: {
  networking.hosts."100.105.204.116" = ["y0usaf-server"];

  finix = {
    diagnostics.enable = true;
    persistence = {
      identity.restoreMachineId = true;
      homeReset.enable = true;
    };
  };

  manzil = {
    finit.conditions = ["task/persist-user-binds/success"];
    clobberByDefault = true;
  };

  services = {
    getty.ttys = ["tty1" "tty2"];
    openssh.settings.Port = [2222];
  };
}
