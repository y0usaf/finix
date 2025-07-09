###############################################################################
# Quickshell Module
# Qt-based desktop shell
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
  inherit (config.shared) username;

  # Generate the main shell.qml content
  shellQml = ''
    import QtQuick
    import QtQuick.Controls
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Hyprland
    import Quickshell.Services.SystemTray
    import Quickshell.Widgets

    ShellRoot {
        ${lib.optionalString cfg.statusBar.enable ''
      // Status Bar
      PanelWindow {
          id: statusBar
          anchors {
              top: ${
        if cfg.statusBar.position == "top"
        then "parent.top"
        else "undefined"
      }
              bottom: ${
        if cfg.statusBar.position == "bottom"
        then "parent.bottom"
        else "undefined"
      }
              left: parent.left
              right: parent.right
          }
          height: ${toString cfg.statusBar.height}

          Rectangle {
              anchors.fill: parent
              color: "#1e1e2e"
              opacity: 0.9

              RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 8

                  // Left side - Workspaces
                  RowLayout {
                      Layout.alignment: Qt.AlignLeft
                      spacing: 4

                      Repeater {
                          model: Hyprland.workspaces

                          WrapperRectangle {
                              Layout.preferredWidth: 30
                              Layout.preferredHeight: 20

                              color: modelData.active ? "#89b4fa" : "#313244"
                              borderRadius: 4

                              Text {
                                  anchors.centerIn: parent
                                  text: modelData.id
                                  color: modelData.active ? "#1e1e2e" : "#cdd6f4"
                                  font.pixelSize: 12
                                  font.bold: modelData.active
                              }

                              MouseArea {
                                  anchors.fill: parent
                                  onClicked: Hyprland.dispatch("workspace", modelData.id)
                              }
                          }
                      }
                  }

                  // Center - Active window title
                  Text {
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignCenter
                      text: Hyprland.activeWindow ? Hyprland.activeWindow.title : "Desktop"
                      color: "#cdd6f4"
                      font.pixelSize: 12
                      elide: Text.ElideRight
                      horizontalAlignment: Text.AlignHCenter
                  }

                  // Right side - System info
                  RowLayout {
                      Layout.alignment: Qt.AlignRight
                      spacing: 8

                      // System tray
                      Repeater {
                          model: SystemTray.items

                          IconImage {
                              Layout.preferredWidth: 20
                              Layout.preferredHeight: 20
                              source: modelData.icon

                              MouseArea {
                                  anchors.fill: parent
                                  onClicked: modelData.activate()
                              }
                          }
                      }

                      // Clock
                      Text {
                          text: Qt.formatDateTime(new Date(), "hh:mm")
                          color: "#cdd6f4"
                          font.pixelSize: 12

                          Timer {
                              interval: 1000
                              running: true
                              repeat: true
                              onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm")
                          }
                      }
                  }
              }
          }
      }
    ''}

        ${lib.optionalString cfg.workspaceOverview.enable ''
      // Workspace Overview
      PopupWindow {
          id: workspaceOverview
          visible: false

          width: 800
          height: 600

          anchors.centerIn: parent

          Rectangle {
              anchors.fill: parent
              color: "#1e1e2e"
              opacity: 0.95
              radius: 8

              ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 20

                  Text {
                      text: "Workspace Overview"
                      color: "#cdd6f4"
                      font.pixelSize: 20
                      font.bold: true
                      Layout.alignment: Qt.AlignCenter
                  }

                  GridLayout {
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      columns: 3
                      rowSpacing: 10
                      columnSpacing: 10

                      Repeater {
                          model: Hyprland.workspaces

                          Rectangle {
                              Layout.fillWidth: true
                              Layout.fillHeight: true
                              Layout.preferredWidth: 200
                              Layout.preferredHeight: 150

                              color: modelData.active ? "#89b4fa" : "#313244"
                              radius: 8
                              border.color: modelData.urgent ? "#f38ba8" : "transparent"
                              border.width: 2

                              ColumnLayout {
                                  anchors.fill: parent
                                  anchors.margins: 10

                                  Text {
                                      text: "Workspace " + modelData.id
                                      color: modelData.active ? "#1e1e2e" : "#cdd6f4"
                                      font.pixelSize: 14
                                      font.bold: true
                                      Layout.alignment: Qt.AlignCenter
                                  }

                                  ListView {
                                      Layout.fillWidth: true
                                      Layout.fillHeight: true

                                      model: Hyprland.toplevels.filter(function(toplevel) {
                                          return toplevel.workspace.id === modelData.id
                                      })

                                      delegate: Text {
                                          width: ListView.view.width
                                          text: modelData.title
                                          color: modelData.active ? "#1e1e2e" : "#cdd6f4"
                                          font.pixelSize: 10
                                          elide: Text.ElideRight
                                          wrapMode: Text.WordWrap
                                          maximumLineCount: 2
                                      }
                                  }
                              }

                              MouseArea {
                                  anchors.fill: parent
                                  onClicked: {
                                      Hyprland.dispatch("workspace", modelData.id)
                                      workspaceOverview.visible = false
                                  }
                              }
                          }
                      }
                  }
              }
          }

          MouseArea {
              anchors.fill: parent
              onClicked: workspaceOverview.visible = false
          }
      }
    ''}

        // IPC for external control
        Component.onCompleted: {
            Quickshell.ipc.register("overview", function(action) {
                if (action === "toggle") {
                    workspaceOverview.visible = !workspaceOverview.visible
                }
            })

            Quickshell.ipc.register("workspaces", function(action) {
                if (action === "toggle") {
                    // Could add workspace indicator popup here
                }
            })
        }
    }
  '';
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };

    statusBar = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable status bar";
      };

      position = lib.mkOption {
        type = lib.types.enum ["top" "bottom"];
        default = "top";
        description = "Status bar position";
      };

      height = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Status bar height in pixels";
      };
    };

    workspaceOverview = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable workspace overview";
      };
    };
  };

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
        jq
      ];

      file.xdg_config."quickshell/shell.qml".text = shellQml;
    };
  };
}
