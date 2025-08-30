sources: _final: prev: {
  obs-studio-plugins =
    prev.obs-studio-plugins
    // {
      obs-backgroundremoval = prev.obs-studio-plugins.obs-backgroundremoval.overrideAttrs (_: {
        src = sources.obs-backgroundremoval;
      });
      obs-vkcapture = prev.obs-studio-plugins.obs-vkcapture.overrideAttrs (_: {
        src = sources.obs-vkcapture;
      });
      obs-pipewire-audio-capture = prev.obs-studio-plugins.obs-pipewire-audio-capture.overrideAttrs (_: {
        src = sources.obs-pipewire-audio-capture;
      });
    };
}
