{
  lib,
  whisper-overlay,
  ...
}: {
  imports = [
    ./core
    ./dev
    ./programs # Renamed from apps
    ./session
    ./shell
    ./tools
    ./ui
  ];
}
