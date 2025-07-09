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

        "quickshell/WorkspaceState.qml".text = ''
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

        "quickshell/SystemMonitor.qml".text = ''
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

        "quickshell/TempDisplay.qml".text = ''
          import QtQuick

          // Minimal temperature display component
          Rectangle {
              id: tempDisplay

              // =====================================================================
              // PROPERTIES
              // =====================================================================
              property string tempValue: "N/A"
              property bool isHigh: false
              property string label: "CPU"

              // =====================================================================
              // APPEARANCE
              // =====================================================================
              width: 60
              height: 20
              color: "#222222"
              border.width: 0
              radius: 0

              // =====================================================================
              // TEXT DISPLAY
              // =====================================================================
              Text {
                  anchors.centerIn: parent
                  text: tempDisplay.tempValue
                  color: tempDisplay.isHigh ? "#ff6b6b" : "#ffffff"
                  font.pixelSize: 12
                  font.bold: false

                  // Subtle transition for temperature changes
                  Behavior on color {
                      ColorAnimation {
                          duration: 300
                          easing.type: Easing.OutCubic
                      }
                  }
              }

              // =====================================================================
              // TOOLTIP (OPTIONAL - SHOWS ON HOVER)
              // =====================================================================
              MouseArea {
                  id: hoverArea
                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.NoButton

                  property bool showTooltip: false

                  onEntered: showTooltip = true
                  onExited: showTooltip = false

                  // Simple tooltip
                  Rectangle {
                      visible: parent.showTooltip && tempDisplay.tempValue !== "N/A"
                      x: parent.width + 5
                      y: (parent.height - height) / 2
                      width: tooltipText.implicitWidth + 8
                      height: 16
                      color: "#333333"
                      radius: 2

                      Text {
                          id: tooltipText
                          anchors.centerIn: parent
                          text: tempDisplay.label + " Temperature"
                          color: "#ffffff"
                          font.pixelSize: 10
                      }
                  }
              }
          }
        '';

        "quickshell/WorkspaceBar.qml".text = ''
          import QtQuick
          import Quickshell
          import Quickshell.Hyprland

          // Minimalist workspace indicator bar
          PanelWindow {
              id: bar

              // =====================================================================
              // PROPERTIES
              // =====================================================================
              property bool isTop: true
              property int currentWorkspace: 1
              property var workspaceWindows: ({})
              property string cpuTemp: "N/A"
              property string gpuTemp: "N/A"
              property bool cpuTempHigh: false
              property bool gpuTempHigh: false

              // =====================================================================
              // CONFIGURATION
              // =====================================================================
              screen: Quickshell.screens[0]
              anchors {
                  top: isTop
                  bottom: !isTop
              }
              margins {
                  top: isTop ? -5 : undefined
                  bottom: isTop ? undefined : -5
                  left: (screen?.width || 0) / 2 - 200
              }

              implicitWidth: 400
              implicitHeight: 30
              color: "transparent"
              mask: Region { item: workspaceRow }
              Behavior on implicitWidth { enabled: false }

              // =====================================================================
              // LAYOUT
              // =====================================================================
              Row {
                  spacing: 20
                  anchors.centerIn: parent

                  // CPU Temperature
                  TempDisplay {
                      tempValue: bar.cpuTemp
                      isHigh: bar.cpuTempHigh
                      label: "CPU"
                  }

                  // GPU Temperature
                  TempDisplay {
                      tempValue: bar.gpuTemp
                      isHigh: bar.gpuTempHigh
                      label: "GPU"
                  }

                  // Workspace indicators
                  Row {
                      id: workspaceRow
                      spacing: 5

                      Repeater {
                          model: 10
                          Rectangle {
                              property int wsId: index + 1
                              property bool hasWindows: (bar.workspaceWindows[wsId] || []).length > 0
                              property bool isActive: wsId === bar.currentWorkspace
                              property bool isOccupied: hasWindows && !isActive

                              width: 20
                              height: 20
                              color: "#222222"
                              visible: isActive || isOccupied || wsId === 1

                              Text {
                                  anchors.centerIn: parent
                                  text: parent.wsId
                                  color: parent.isActive ? "#ffffff" : parent.isOccupied ? "#aaaaaa" : "#666666"
                                  font.pixelSize: 12
                              }

                              MouseArea {
                                  anchors.fill: parent
                                  onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                              }
                          }
                      }
                  }

                  // Date display
                  Rectangle {
                      width: 60
                      height: 20
                      color: "#222222"

                      Text {
                          id: dateText
                          anchors.centerIn: parent
                          text: Qt.formatDateTime(new Date(), "dd/MM/yy")
                          color: "#ffffff"
                          font.pixelSize: 12

                          Timer {
                              interval: 60000
                              running: true
                              repeat: true
                              onTriggered: dateText.text = Qt.formatDateTime(new Date(), "dd/MM/yy")
                          }
                      }
                  }

                  // Time display
                  Rectangle {
                      width: 60
                      height: 20
                      color: "#222222"

                      Text {
                          id: timeText
                          anchors.centerIn: parent
                          text: Qt.formatDateTime(new Date(), "HH:mm:ss")
                          color: "#ffffff"
                          font.pixelSize: 12

                          Timer {
                              interval: 1000
                              running: true
                              repeat: true
                              onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm:ss")
                          }
                      }
                  }
              }
          }
        '';

        "quickshell/WorkspaceOverview.qml".text = ''
          import QtQuick
          import Quickshell
          import Quickshell.Hyprland

          // Workspace overview overlay
          PanelWindow {
              id: overview

              // =====================================================================
              // PROPERTIES
              // =====================================================================
              property bool shouldShow: false
              property int currentWorkspace: 1
              property var workspaceWindows: ({})
              property bool manuallyTriggered: false

              visible: shouldShow
              screen: Quickshell.screens[0]

              readonly property var activeWorkspaces: {
                      const workspaces = new Set([overview.currentWorkspace])
                      Object.keys(overview.workspaceWindows).forEach(wsId => {
                          if (overview.workspaceWindows[wsId].length > 0) {
                              workspaces.add(parseInt(wsId))
                          }
                      })
                      return Array.from(workspaces).sort((a, b) => a - b)
              }

              readonly property int stableWidth: Math.min(
                  Math.max(10 * 180 + 9 * 20 + 40, 800),
                  (screen?.width || 1920) * 0.9
              )

              margins {
                  left: screen ? (screen.width - stableWidth) / 2 : 100
                  top: screen ? (screen.height - 300) / 2 : 100
              }

              implicitWidth: stableWidth
              implicitHeight: 300
              color: "transparent"
              mask: Region {}

              Behavior on implicitWidth { enabled: false }
              Behavior on width { enabled: false }

              // =====================================================================
              // CONTENT
              // =====================================================================
              Flickable {
                  anchors.centerIn: parent
                  width: Math.min(parent.width - 20, contentWidth)
                  height: 160
                  contentWidth: workspaceRow.width
                  contentHeight: workspaceRow.height
                  clip: true

                  Row {
                      id: workspaceRow
                      spacing: 20

                      Repeater {
                          model: overview.activeWorkspaces

                          WorkspacePreview {
                              workspaceId: modelData
                              currentWorkspace: overview.currentWorkspace
                              windows: overview.workspaceWindows[modelData] || []
                          }
                      }
                  }
              }

              // Click-to-dismiss
              MouseArea {
                  anchors.fill: parent
                  enabled: overview.manuallyTriggered
                  onClicked: {
                      overview.shouldShow = false
                      overview.manuallyTriggered = false
                  }
              }

              // =====================================================================
              // WORKSPACE PREVIEW COMPONENT
              // =====================================================================
              component WorkspacePreview: Item {
                  property int workspaceId: 1
                  property int currentWorkspace: 1
                  property bool isFocused: workspaceId === currentWorkspace
                  property var windows: []

                  width: 160
                  height: 140

                  Item {
                      id: displayArea
                      width: parent.width
                      height: 120
                      clip: true

                      // Empty workspace indicator
                      Rectangle {
                          visible: windows.length === 0
                          x: Math.round(displayArea.offsetX)
                          y: Math.round(displayArea.offsetY)
                          width: Math.max(Math.round(displayArea.scaledWidth), 2)
                          height: Math.max(Math.round(displayArea.scaledHeight), 2)
                          color: "transparent"
                          border.width: 1
                          border.color: "#ffffff"
                          opacity: 0.9
                      }

                      // Workspace bounds calculation
                      readonly property var workspaceBounds: {
                          const screenWidth = 5120, screenHeight = 1440
                          if (windows.length === 0) return {minX: 0, minY: 0, maxX: screenWidth, maxY: screenHeight}

                          let minX = Infinity, minY = Infinity, maxX = 0, maxY = 0
                          windows.forEach(win => {
                              const x = win.at?.[0] || 0, y = win.at?.[1] || 0
                              const w = win.size?.[0] || 400, h = win.size?.[1] || 300
                              minX = Math.min(minX, x); minY = Math.min(minY, y)
                              maxX = Math.max(maxX, x + w); maxY = Math.max(maxY, y + h)
                          })

                          const actualWidth = maxX - minX, actualHeight = maxY - minY
                          if (actualWidth < screenWidth * 0.5) {
                              const center = minX + actualWidth / 2
                              minX = center - screenWidth * 0.25; maxX = center + screenWidth * 0.25
                          }
                          if (actualHeight < screenHeight * 0.5) {
                              const center = minY + actualHeight / 2
                              minY = center - screenHeight * 0.25; maxY = center + screenHeight * 0.25
                          }
                          return {minX, minY, maxX, maxY}
                      }

                      // Scaling calculations
                      readonly property real workspaceWidth: workspaceBounds.maxX - workspaceBounds.minX
                      readonly property real workspaceHeight: workspaceBounds.maxY - workspaceBounds.minY
                      readonly property real workspaceAspect: workspaceWidth / workspaceHeight
                      readonly property real previewAspect: width / height
                      readonly property real aspectCorrection: workspaceAspect > (previewAspect * 2) ? 0.5 : 1.0
                      readonly property real effectiveWorkspaceWidth: workspaceWidth * aspectCorrection
                      readonly property real scale: Math.min(width / effectiveWorkspaceWidth, height / workspaceHeight) * 0.85
                      readonly property real scaledWidth: effectiveWorkspaceWidth * scale
                      readonly property real scaledHeight: workspaceHeight * scale
                      readonly property real offsetX: (width - scaledWidth) / 2
                      readonly property real offsetY: (height - scaledHeight) / 2

                      // Window representations
                      Repeater {
                          model: windows
                          Rectangle {
                              required property var modelData
                              readonly property real winX: modelData.at?.[0] || 0
                              readonly property real winY: modelData.at?.[1] || 0
                              readonly property real winWidth: modelData.size?.[0] || 400
                              readonly property real winHeight: modelData.size?.[1] || 300

                              x: Math.round(displayArea.offsetX + (winX - displayArea.workspaceBounds.minX) * displayArea.aspectCorrection * displayArea.scale)
                              y: Math.round(displayArea.offsetY + (winY - displayArea.workspaceBounds.minY) * displayArea.scale)
                              width: Math.max(Math.round(winWidth * displayArea.aspectCorrection * displayArea.scale), 2)
                              height: Math.max(Math.round(winHeight * displayArea.scale), 2)

                              color: "transparent"
                              border.width: 1
                              border.color: "#ffffff"
                              opacity: 0.9

                              Text {
                                  anchors.centerIn: parent
                                  text: {
                                      const appClass = modelData.class || ""
                                      const appNames = {
                                          "firefox": "Firefox", "stremio": "Stremio", "discord": "Discord",
                                          "foot": "Foot", "zellij": "Zellij", "code": "Code", "chrome": "Chrome"
                                      }
                                      for (const [key, name] of Object.entries(appNames)) {
                                          if (appClass.includes(key)) return name
                                      }
                                      return appClass || modelData.title?.split(" ")[0] || ""
                                  }
                                  color: "#ffffff"
                                  font.pixelSize: Math.max(6, Math.min(parent.width / 8, parent.height / 4))
                                  font.bold: true
                                  visible: parent.width > 25 && parent.height > 15
                                  horizontalAlignment: Text.AlignHCenter
                                  verticalAlignment: Text.AlignVCenter
                                  clip: true
                                  elide: Text.ElideRight
                              }
                          }
                      }
                  }

                  // Workspace ID label
                  Text {
                      anchors.top: displayArea.bottom
                      anchors.horizontalCenter: displayArea.horizontalCenter
                      anchors.topMargin: 4
                      text: workspaceId
                      color: isFocused ? "#ffffff" : (windows.length > 0 ? "#888888" : "#444444")
                      font.pixelSize: 14
                      font.bold: true
                  }
              }
          }
        '';
      };
    };
  };
}
