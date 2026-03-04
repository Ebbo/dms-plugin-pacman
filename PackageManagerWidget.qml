import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./components"

PluginComponent {
    id: root

    property bool showVersions: pluginData.showVersions !== undefined ? pluginData.showVersions : true

    Ref {
        service: PackageManagerService
    }

    // --- Global Variables ---

    PluginGlobalVar {
        id: globalUpdateCount
        varName: "updateCount"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalUpdates
        varName: "updates"
        defaultValue: []
    }

    PluginGlobalVar {
        id: globalOfficialUpdates
        varName: "officialUpdates"
        defaultValue: []
    }

    PluginGlobalVar {
        id: globalAurUpdates
        varName: "aurUpdates"
        defaultValue: []
    }

    PluginGlobalVar {
        id: globalLastCheckTime
        varName: "lastCheckTime"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: globalIsChecking
        varName: "isChecking"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalAurHelper
        varName: "aurHelper"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: globalInitialized
        varName: "initialized"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalErrorMessage
        varName: "errorMessage"
        defaultValue: ""
    }

    // --- List Models ---

    ListModel {
        id: officialModel
    }

    ListModel {
        id: aurModel
    }

    property string _lastOfficialHash: ""
    property string _lastAurHash: ""

    function syncModels() {
        var official = globalOfficialUpdates.value || [];
        var aur = globalAurUpdates.value || [];

        // Sync official model
        var oHash = official.map(function(p) { return p.name + p.newVersion; }).join(",");
        if (oHash !== _lastOfficialHash) {
            _lastOfficialHash = oHash;
            officialModel.clear();
            for (var i = 0; i < official.length; i++) {
                officialModel.append(official[i]);
            }
        }

        // Sync AUR model
        var aHash = aur.map(function(p) { return p.name + p.newVersion; }).join(",");
        if (aHash !== _lastAurHash) {
            _lastAurHash = aHash;
            aurModel.clear();
            for (var j = 0; j < aur.length; j++) {
                aurModel.append(aur[j]);
            }
        }
    }

    Connections {
        target: globalOfficialUpdates
        function onValueChanged() { syncModels(); }
    }

    Connections {
        target: globalAurUpdates
        function onValueChanged() { syncModels(); }
    }

    Component.onCompleted: syncModels()

    // --- Status Bar ---

    horizontalBarPill: StatusBarContent {
        orientation: Qt.Horizontal
        updateCount: globalUpdateCount.value
        isChecking: globalIsChecking.value
        hasError: (globalErrorMessage.value || "") !== ""
        barThickness: root.barThickness
    }

    verticalBarPill: StatusBarContent {
        orientation: Qt.Vertical
        updateCount: globalUpdateCount.value
        isChecking: globalIsChecking.value
        hasError: (globalErrorMessage.value || "") !== ""
        barThickness: root.barThickness
    }

    // --- Popout ---

    popoutContent: Component {
        FocusScope {
            id: popoutScope
            implicitWidth: 380
            implicitHeight: 500
            focus: true

            property bool contentReady: true
            property var parentPopout: null

            Keys.onPressed: event => {
                if (event.key === Qt.Key_R && event.modifiers & Qt.ControlModifier) {
                    PackageManagerService.checkUpdates();
                    event.accepted = true;
                } else if (event.key === Qt.Key_U && event.modifiers & Qt.ControlModifier) {
                    PackageManagerService.launchUpdate();
                    event.accepted = true;
                }
            }

            Column {
                id: mainColumn
                width: parent.width
                spacing: 0

                // --- Header ---
                Rectangle {
                    width: parent.width
                    height: 56
                    color: "transparent"

                    Column {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.spacingM
                            verticalCenter: parent.verticalCenter
                            right: headerButtons.left
                            rightMargin: Theme.spacingS
                        }
                        spacing: 2

                        Row {
                            spacing: Theme.spacingS

                            // Status indicator dot
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: {
                                    if ((globalErrorMessage.value || "") !== "") return Theme.error;
                                    if (globalIsChecking.value) return Theme.surfaceVariantText;
                                    if (globalUpdateCount.value > 0) return Theme.warning || "#ff9800";
                                    return "#4caf50";
                                }
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            StyledText {
                                text: {
                                    if (globalIsChecking.value) return "Checking for updates...";
                                    if ((globalErrorMessage.value || "") !== "") return "Error checking updates";
                                    var count = globalUpdateCount.value;
                                    if (count === 0) return "System is up to date";
                                    return count + " update" + (count !== 1 ? "s" : "") + " available";
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                    }

                    Row {
                        id: headerButtons
                        anchors {
                            right: parent.right
                            rightMargin: Theme.spacingS
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.spacingXS

                        // Refresh button
                        Rectangle {
                            width: 36; height: 36; radius: Theme.cornerRadius
                            color: refreshMa.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                            DankIcon {
                                id: refreshIcon
                                name: "refresh"
                                size: 18
                                color: Theme.surfaceText
                                anchors.centerIn: parent
                                rotation: 0

                                RotationAnimation {
                                    id: refreshSpin
                                    target: refreshIcon
                                    running: globalIsChecking.value
                                    from: 0; to: 360
                                    duration: 1500
                                    loops: Animation.Infinite
                                }

                                Connections {
                                    target: globalIsChecking
                                    function onValueChanged() {
                                        if (!globalIsChecking.value) {
                                            refreshSpin.stop();
                                            refreshIcon.rotation = 0;
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: refreshMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: PackageManagerService.checkUpdates()
                            }
                        }

                        // Update button
                        Rectangle {
                            visible: globalUpdateCount.value > 0
                            width: updateRow.implicitWidth + Theme.spacingM * 2
                            height: 36
                            radius: Theme.cornerRadius
                            color: updateMa.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary

                            Row {
                                id: updateRow
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "terminal"
                                    size: 16
                                    color: Theme.onPrimary || "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Update"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.onPrimary || "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: updateMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: PackageManagerService.launchUpdate()
                            }
                        }
                    }
                }

                // --- Separator ---
                Rectangle {
                    width: parent.width - Theme.spacingM * 2
                    height: 1
                    color: Theme.outlineVariant
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // --- Info bar ---
                StyledText {
                    text: {
                        var parts = [];
                        var lastCheck = globalLastCheckTime.value;
                        if (lastCheck) parts.push("Last check: " + lastCheck);
                        var helper = globalAurHelper.value;
                        if (helper) parts.push(helper + " (detected)");
                        else parts.push("pacman only");
                        return parts.join("  \u2022  ");
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    opacity: 0.7
                    leftPadding: Theme.spacingM
                    topPadding: Theme.spacingXS
                    bottomPadding: Theme.spacingXS
                }

                // --- Content ---
                Flickable {
                    id: updateList
                    width: parent.width
                    height: popoutScope.implicitHeight - 80
                    contentHeight: updateContent.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: updateContent
                        width: parent.width
                        spacing: 0

                        // Empty / Checking / Error state (single instance)
                        EmptyState {
                            width: parent.width
                            height: updateList.height
                            visible: globalUpdateCount.value === 0 || globalIsChecking.value
                            initialized: globalInitialized.value
                            isChecking: globalIsChecking.value
                            errorMessage: globalIsChecking.value ? "" : (globalErrorMessage.value || "")
                            updateCount: globalUpdateCount.value
                        }

                        // --- Official Updates Section ---
                        Column {
                            width: parent.width
                            visible: officialModel.count > 0 && !globalIsChecking.value
                            spacing: Theme.spacingXS
                            topPadding: Theme.spacingS
                            leftPadding: Theme.spacingM
                            rightPadding: Theme.spacingM

                            Row {
                                spacing: Theme.spacingXS
                                StyledText {
                                    text: "Official Repository"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: officialCountText.implicitWidth + 8
                                    height: officialCountText.implicitHeight + 2
                                    radius: height / 2
                                    color: Theme.surfaceContainerHigh
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        id: officialCountText
                                        text: officialModel.count.toString()
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.surfaceVariantText
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Repeater {
                                model: officialModel
                                delegate: PackageCard {
                                    width: parent.width - Theme.spacingM * 2
                                    packageName: model.name
                                    oldVersion: model.oldVersion
                                    newVersion: model.newVersion
                                    source: "official"
                                    showVersions: root.showVersions
                                }
                            }
                        }

                        // --- AUR Updates Section ---
                        Column {
                            width: parent.width
                            visible: aurModel.count > 0 && !globalIsChecking.value
                            spacing: Theme.spacingXS
                            topPadding: Theme.spacingS
                            leftPadding: Theme.spacingM
                            rightPadding: Theme.spacingM
                            bottomPadding: Theme.spacingM

                            Row {
                                spacing: Theme.spacingXS
                                StyledText {
                                    text: "AUR"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: aurCountText.implicitWidth + 8
                                    height: aurCountText.implicitHeight + 2
                                    radius: height / 2
                                    color: Theme.surfaceContainerHigh
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        id: aurCountText
                                        text: aurModel.count.toString()
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.surfaceVariantText
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Repeater {
                                model: aurModel
                                delegate: PackageCard {
                                    width: parent.width - Theme.spacingM * 2
                                    packageName: model.name
                                    oldVersion: model.oldVersion
                                    newVersion: model.newVersion
                                    source: "aur"
                                    showVersions: root.showVersions
                                }
                            }
                        }

                        // Bottom padding
                        Item {
                            width: 1
                            height: Theme.spacingM
                            visible: globalUpdateCount.value > 0
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 380
    popoutHeight: 500
}
