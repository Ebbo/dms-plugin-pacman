import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    property bool initialized: false
    property bool isChecking: false
    property string errorMessage: ""
    property int updateCount: 0

    spacing: Theme.spacingM

    onIsCheckingChanged: {
        if (!isChecking) {
            spinTimer.stop();
            stateIcon.rotation = 0;
        }
    }

    Item {
        width: parent.width
        height: parent.height / 4
    }

    DankIcon {
        id: stateIcon
        name: {
            if (root.errorMessage) return "error";
            if (root.isChecking) return "sync";
            return "check_circle";
        }
        size: 48
        color: {
            if (root.errorMessage) return Theme.error;
            if (root.isChecking) return Theme.surfaceVariantText;
            return "#4caf50";
        }
        anchors.horizontalCenter: parent.horizontalCenter
        rotation: 0
    }

    Timer {
        id: spinTimer
        interval: 16
        repeat: true
        running: root.isChecking
        onTriggered: stateIcon.rotation = (stateIcon.rotation + 4) % 360
    }

    StyledText {
        text: {
            if (root.errorMessage) return "Configuration Error";
            if (root.isChecking) return "Checking for updates...";
            if (!root.initialized) return "Initializing...";
            return "System is up to date";
        }
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: root.errorMessage ? Theme.error : Theme.surfaceText
        anchors.horizontalCenter: parent.horizontalCenter
    }

    StyledText {
        text: {
            if (root.errorMessage) return root.errorMessage;
            if (root.isChecking) return "This may take a moment...";
            if (!root.initialized) return "Detecting package managers...";
            return "All packages are at their latest versions.";
        }
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Theme.spacingL * 2
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
