import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string packageName: ""
    property string oldVersion: ""
    property string newVersion: ""
    property string source: "official"  // "official" or "aur"
    property bool showVersions: true

    width: parent ? parent.width : 200
    height: contentCol.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: "transparent"

    Column {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacingS
            rightMargin: Theme.spacingS + sourceBadge.width + Theme.spacingXS
        }
        spacing: 2

        StyledText {
            text: root.packageName
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            elide: Text.ElideRight
            width: parent.width
        }

        Row {
            visible: root.showVersions
            spacing: Theme.spacingXS
            width: parent.width

            StyledText {
                text: root.oldVersion
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideMiddle
                width: (parent.width - arrowText.width - Theme.spacingXS * 2) / 2
            }

            StyledText {
                id: arrowText
                text: "\u2192"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
            }

            StyledText {
                text: root.newVersion
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.primary
                elide: Text.ElideMiddle
                width: (parent.width - arrowText.width - Theme.spacingXS * 2) / 2
            }
        }
    }

    // Source badge
    Rectangle {
        id: sourceBadge
        anchors {
            right: parent.right
            top: parent.top
            margins: Theme.spacingS
        }
        width: sourceText.implicitWidth + 8
        height: sourceText.implicitHeight + 4
        radius: height / 2
        color: root.source === "aur" ? (Theme.tertiaryContainer || Theme.surfaceContainerHigh) : (Theme.primaryContainer || Theme.surfaceContainerHigh)

        StyledText {
            id: sourceText
            text: root.source === "aur" ? "AUR" : "repo"
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Font.Medium
            color: root.source === "aur" ? (Theme.onTertiaryContainer || Theme.surfaceText) : (Theme.onPrimaryContainer || Theme.surfaceText)
            anchors.centerIn: parent
        }
    }
}
