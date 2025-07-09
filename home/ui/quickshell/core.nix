###############################################################################
# Quickshell Core Components
# Core QML components for state management and system monitoring
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.quickshell;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config = {
      "quickshell/core/qmldir".text = ''
        WorkspaceState 1.0 WorkspaceState.qml
        SystemMonitor 1.0 SystemMonitor.qml
      '';

      "quickshell/core/WorkspaceState.qml".text = ''
        import QtQuick
        import Quickshell.Hyprland
        import Quickshell.Io

        // Centralized workspace state management
        QtObject {
            id: state

            // =====================================================================
            // CORE STATE
            // =====================================================================
            property bool shouldShowOverlay: false
            property int currentWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id || 1
            property var workspaceWindows: ({})
            property bool manuallyTriggered: false
            property bool holdMode: false
            property bool workspacesVisible: true

            // =====================================================================
            // DATA FETCHING
            // =====================================================================
            readonly property Process windowsProcess: Process {
                command: ["hyprctl", "clients", "-j"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const windows = JSON.parse(this.text)
                            const workspaceMap = {}
                            windows.forEach(win => {
                                const wsId = win.workspace.id
                                if (!workspaceMap[wsId]) workspaceMap[wsId] = []
                                workspaceMap[wsId].push(win)
                            })
                            state.workspaceWindows = workspaceMap
                        } catch (e) {
                            console.warn("Failed to parse window data:", e)
                        }
                    }
                }
            }

            // =====================================================================
            // EVENT HANDLING
            // =====================================================================
            readonly property Connections hyprlandEvents: Connections {
                target: Hyprland
                function onRawEvent(event) {
                    const relevantEvents = ["openwindow", "closewindow", "movewindow", "resizewindow", "workspace", "createworkspace", "destroyworkspace", "windowtitle"]
                    if (relevantEvents.some(eventType => event.name.includes(eventType))) {
                        windowsProcess.running = true
                    }
                }
            }

            // =====================================================================
            // TIMERS
            // =====================================================================
            readonly property Timer hideTimer: Timer {
                interval: 500
                onTriggered: {
                    if (!state.manuallyTriggered) {
                        state.shouldShowOverlay = false
                    }
                }
            }

            readonly property Timer manualHideTimer: Timer {
                interval: 2000
                onTriggered: {
                    if (!state.holdMode) {
                        state.shouldShowOverlay = false
                        state.manuallyTriggered = false
                    }
                }
            }

            // =====================================================================
            // CONTROL FUNCTIONS
            // =====================================================================
            function toggleOverview() {
                manuallyTriggered = true
                holdMode = false
                shouldShowOverlay = !shouldShowOverlay
                if (shouldShowOverlay) manualHideTimer.restart()
            }

            function showOverview() {
                manuallyTriggered = true
                holdMode = true
                shouldShowOverlay = true
            }

            function hideOverview() {
                if (holdMode) {
                    shouldShowOverlay = false
                    manuallyTriggered = false
                    holdMode = false
                }
            }

            function toggleWorkspaces() { workspacesVisible = !workspacesVisible }
            function showWorkspaces() { workspacesVisible = true }
            function hideWorkspaces() { workspacesVisible = false }
            function refreshWindows() { windowsProcess.running = true }

            // =====================================================================
            // AUTO-HANDLERS
            // =====================================================================
            onCurrentWorkspaceChanged: {
                if (!manuallyTriggered) {
                    shouldShowOverlay = true
                    hideTimer.restart()
                }
            }

            Component.onCompleted: refreshWindows()
        }
      '';

      "quickshell/core/SystemMonitor.qml".text = ''
        import QtQuick
        import Quickshell.Io

        // Minimal system monitoring for CPU/GPU temperatures
        QtObject {
            id: monitor

            // =====================================================================
            // TEMPERATURE PROPERTIES
            // =====================================================================
            property string cpuTemp: "N/A"
            property string gpuTemp: "N/A"
            property bool cpuTempHigh: false
            property bool gpuTempHigh: false

            readonly property int highTempThreshold: 75 // °C
            readonly property int updateInterval: 2000 // 2 seconds

            // =====================================================================
            // CPU TEMPERATURE MONITORING
            // =====================================================================
            readonly property Process cpuTempProcess: Process {
                command: ["bash", "-c", "sensors 2>/dev/null | grep -E 'Tctl|Package id 0|Core 0' | head -1 | awk '{print $2}' | sed 's/[+°C]//g' || echo 'N/A'"]

                stdout: StdioCollector {
                    onStreamFinished: {
                        const temp = this.text.trim()
                        if (temp && temp !== "N/A" && !isNaN(parseFloat(temp))) {
                            const tempNum = Math.round(parseFloat(temp))
                            monitor.cpuTemp = tempNum + "°C"
                            monitor.cpuTempHigh = tempNum > monitor.highTempThreshold
                        } else {
                            monitor.cpuTemp = "N/A"
                            monitor.cpuTempHigh = false
                        }
                    }
                }
            }

            // =====================================================================
            // GPU TEMPERATURE MONITORING (NVIDIA)
            // =====================================================================
            readonly property Process gpuTempProcess: Process {
                command: ["bash", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 'N/A'"]

                stdout: StdioCollector {
                    onStreamFinished: {
                        const temp = this.text.trim()
                        if (temp && temp !== "N/A" && !isNaN(parseFloat(temp))) {
                            const tempNum = Math.round(parseFloat(temp))
                            monitor.gpuTemp = tempNum + "°C"
                            monitor.gpuTempHigh = tempNum > monitor.highTempThreshold
                        } else {
                            monitor.gpuTemp = "N/A"
                            monitor.gpuTempHigh = false
                        }
                    }
                }
            }

            // =====================================================================
            // UPDATE TIMER
            // =====================================================================
            readonly property Timer updateTimer: Timer {
                interval: monitor.updateInterval
                running: true
                repeat: true
                onTriggered: {
                    cpuTempProcess.running = true
                    gpuTempProcess.running = true
                }
            }

            // =====================================================================
            // INITIALIZATION
            // =====================================================================
            Component.onCompleted: {
                cpuTempProcess.running = true
                gpuTempProcess.running = true
            }
        }
      '';
    };
  };
}
