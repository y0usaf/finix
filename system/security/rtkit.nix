###############################################################################
# RTKit Security Module
# Real-time kit for audio/video tasks:
# - Enables real-time priority for audio/video applications
# - Ensures smoother multimedia performance
###############################################################################
_: {
  config = {
    ###########################################################################
    # RTKit Configuration
    # Enable real-time priority management for multimedia applications
    ###########################################################################
    security.rtkit.enable = true; # Enable real-time priority management (often needed for audio/video tasks)
  };
}
