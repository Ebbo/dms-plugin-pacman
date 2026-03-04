import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import "../services"

Item {
    id: root

    property int orientation: Qt.Horizontal
    property int updateCount: 0
    property bool isChecking: false
    property bool hasError: false
    property real barThickness: 0

    implicitWidth: root.orientation === Qt.Vertical ? root.barThickness : contentRow.implicitWidth
    implicitHeight: root.orientation === Qt.Vertical ? contentColumn.implicitHeight : root.barThickness

    // Color based on state
    readonly property color iconColor: {
        if (root.hasError) return Theme.error;
        if (root.isChecking) return Theme.surfaceVariantText;
        if (root.updateCount > 0) return Theme.warning || "#ffb74d";
        return "#66ff66"; // Green - up to date
    }

    function openContextMenu() {
        var globalPos = root.mapToGlobal(root.width / 2, root.height / 2);
        var gx = globalPos.x;
        var gy = globalPos.y;

        // Find which screen the icon is on
        var screens = Quickshell.screens;
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i];
            if (gx >= s.x && gx < s.x + s.width && gy >= s.y && gy < s.y + s.height) {
                contextMenuWindow.screen = s;
                contextMenuWindow.anchorX = gx - s.x;
                contextMenuWindow.anchorY = gy - s.y;
                contextMenuWindow.visible = true;
                return;
            }
        }

        // Fallback
        contextMenuWindow.anchorX = gx;
        contextMenuWindow.anchorY = gy;
        contextMenuWindow.visible = true;
    }

    // Right-click handler
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            openContextMenu();
        }
    }

    // Context menu overlay
    PanelWindow {
        id: contextMenuWindow

        WlrLayershell.namespace: "dms:pacman-context-menu"

        property real anchorX: 0
        property real anchorY: 0

        visible: false
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        // Dismiss on click outside
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: contextMenuWindow.visible = false
        }

        // Menu container
        Rectangle {
            id: menuContainer

            x: {
                var want = contextMenuWindow.anchorX - width / 2;
                return Math.max(10, Math.min(contextMenuWindow.width - width - 10, want));
            }
            y: {
                // Try below the bar first, if not enough space go above
                var below = contextMenuWindow.anchorY + root.barThickness / 2 + 4;
                if (below + height > contextMenuWindow.height - 10) {
                    return contextMenuWindow.anchorY - root.barThickness / 2 - height - 4;
                }
                return below;
            }

            width: Math.min(240, Math.max(170, menuColumn.implicitWidth + Theme.spacingS * 2))
            height: menuColumn.implicitHeight + Theme.spacingS * 2
            color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
            radius: Theme.cornerRadius
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: 1

            opacity: contextMenuWindow.visible ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.emphasizedEasing
                }
            }

            // Shadow
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 4
                anchors.leftMargin: 2
                anchors.rightMargin: -2
                anchors.bottomMargin: -4
                radius: parent.radius
                color: Qt.rgba(0, 0, 0, 0.15)
                z: -1
            }

            Column {
                id: menuColumn
                width: parent.width - Theme.spacingS * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingS
                spacing: 1

                // Update System item
                Rectangle {
                    visible: root.updateCount > 0
                    width: parent.width
                    height: visible ? 30 : 0
                    radius: Theme.cornerRadius
                    color: updateArea.containsMouse ? Theme.widgetBaseHoverColor : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "terminal"
                            size: 16
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Update System (" + root.updateCount + ")"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: updateArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            contextMenuWindow.visible = false;
                            PackageManagerService.launchUpdate();
                        }
                    }
                }

                // Refresh item
                Rectangle {
                    width: parent.width
                    height: 30
                    radius: Theme.cornerRadius
                    color: refreshArea.containsMouse ? Theme.widgetBaseHoverColor : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "refresh"
                            size: 16
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Refresh"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            contextMenuWindow.visible = false;
                            PackageManagerService.checkUpdates();
                        }
                    }
                }
            }
        }
    }

    // Horizontal Layout
    Row {
        id: contentRow
        visible: root.orientation === Qt.Horizontal
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            id: hIcon
            name: root.updateCount > 0 ? "system_update" : "check_circle"
            size: Theme.barIconSize(root.barThickness, -6)
            color: root.iconColor
            anchors.verticalCenter: parent.verticalCenter
            opacity: 1

            SequentialAnimation {
                id: hPulse
                running: root.isChecking
                loops: Animation.Infinite
                NumberAnimation { target: hIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { target: hIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                onRunningChanged: {
                    if (!running) hIcon.opacity = 1;
                }
            }
        }

        // Update count badge
        Rectangle {
            visible: root.updateCount > 0 && !root.isChecking
            width: countText.implicitWidth + 8
            height: countText.implicitHeight + 4
            radius: height / 2
            color: Theme.warning || "#ff9800"
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                id: countText
                text: root.updateCount.toString()
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: "#000000"
                anchors.centerIn: parent
            }
        }
    }

    // Vertical Layout
    Column {
        id: contentColumn
        visible: root.orientation === Qt.Vertical
        anchors.centerIn: parent
        spacing: 2

        DankIcon {
            id: vIcon
            name: root.updateCount > 0 ? "system_update" : "check_circle"
            size: Theme.barIconSize(root.barThickness, -6)
            color: root.iconColor
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 1

            SequentialAnimation {
                id: vPulse
                running: root.isChecking
                loops: Animation.Infinite
                NumberAnimation { target: vIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { target: vIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                onRunningChanged: {
                    if (!running) vIcon.opacity = 1;
                }
            }
        }

        Rectangle {
            visible: root.updateCount > 0 && !root.isChecking
            width: countTextV.implicitWidth + 8
            height: countTextV.implicitHeight + 4
            radius: height / 2
            color: Theme.warning || "#ff9800"
            anchors.horizontalCenter: parent.horizontalCenter

            StyledText {
                id: countTextV
                text: root.updateCount.toString()
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: "#000000"
                anchors.centerIn: parent
            }
        }
    }
}
