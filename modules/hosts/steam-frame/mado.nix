{
  frameSession,
  madoPackages,
  ...
}: {
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
