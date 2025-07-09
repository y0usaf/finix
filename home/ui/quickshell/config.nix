###############################################################################
# Quickshell Module Configuration
# Main configuration for packages and shell file
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
  inherit (config.shared) username;
in {
  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        quickshell
        cava
      ];

      file.xdg_config = {
        "quickshell/shell.qml".text = ''
          import QtQuick
          import Quickshell
          import Quickshell.Io

          // Component imports handled by QML loader
          import "./core"
          import "./components"

          ShellRoot {
              // =====================================================================
              // CORE STATE MANAGEMENT
              // =====================================================================
              WorkspaceState {
                  id: workspaceState
              }

              SystemMonitor {
                  id: systemMonitor
              }

              // =====================================================================
              // IPC HANDLERS
              // =====================================================================
              IpcHandler {
                  target: "overview"
                  function toggle(): void { workspaceState.toggleOverview() }
                  function display(): void { workspaceState.showOverview() }
                  function dismiss(): void { workspaceState.hideOverview() }
              }

              IpcHandler {
                  target: "workspaces"
                  function toggle(): void { workspaceState.toggleWorkspaces() }
                  function show(): void { workspaceState.showWorkspaces() }
                  function hide(): void { workspaceState.hideWorkspaces() }
              }

              // =====================================================================
              // UI COMPONENTS
              // =====================================================================

              // Top workspace bar
              WorkspaceBar {
                  isTop: true
                  visible: workspaceState.workspacesVisible
                  currentWorkspace: workspaceState.currentWorkspace
                  workspaceWindows: workspaceState.workspaceWindows
                  cpuTemp: systemMonitor.cpuTemp
                  gpuTemp: systemMonitor.gpuTemp
                  cpuTempHigh: systemMonitor.cpuTempHigh
                  gpuTempHigh: systemMonitor.gpuTempHigh
              }

              // Bottom workspace bar
              WorkspaceBar {
                  isTop: false
                  visible: workspaceState.workspacesVisible
                  currentWorkspace: workspaceState.currentWorkspace
                  workspaceWindows: workspaceState.workspaceWindows
                  cpuTemp: systemMonitor.cpuTemp
                  gpuTemp: systemMonitor.gpuTemp
                  cpuTempHigh: systemMonitor.cpuTempHigh
                  gpuTempHigh: systemMonitor.gpuTempHigh
              }

              // Workspace overview overlay
              WorkspaceOverview {
                  shouldShow: workspaceState.shouldShowOverlay
                  currentWorkspace: workspaceState.currentWorkspace
                  workspaceWindows: workspaceState.workspaceWindows
                  manuallyTriggered: workspaceState.manuallyTriggered
              }
          }
        '';
      };
    };
  };
}
