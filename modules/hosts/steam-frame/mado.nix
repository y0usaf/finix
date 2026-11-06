{
  config,
  frameSession,
  madoPackages,
  pkgs,
  ...
}: {
  frame.session.fhsPackages = [
    (pkgs.makeDesktopItem {
      name = "mado";
      desktopName = "mado";
      comment = "The PC's monitors as panels in the headset";
      exec = "${config.systemd.package}/bin/systemctl --user restart mado";
    })
  ];

  systemd.user.services.mado = {
    description = "mado-view, the PC's mado stream in the headset";
    bindsTo = ["steamvr.service"];
    after = ["steamvr.service"];
    wantedBy = ["steamvr.service"];
    environment = frameSession.valveMesaEnv // {DISABLE_VULKAN_FDM_INJECTION_LAYER = "1";};
    serviceConfig = {
      Slice = "session.slice";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 10;
      EnvironmentFile = frameSession.mesavars;
      ExecStart = frameSession.inFhs "${madoPackages.mado-view}/bin/mado-view 192.168.2.201 --stats";
    };
  };
}
