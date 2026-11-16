import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl

AppCard {
    id: root

    property bool hasRecord: false
    property string recordTitle: ""
    property var fields: []
    property bool busy: false
    property bool changeAllowed: false
    property bool deleteAllowed: false
    property string deleteLabel: "Удалить запись"
    property url deleteIcon: Qt.resolvedUrl("../icons/trash.svg")

    signal editRequested()
    signal deleteRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            AppText {
                Layout.fillWidth: true
                font.bold: true
                textFormat: Text.PlainText
                elide: Text.ElideRight
                text: root.hasRecord ? root.recordTitle : "Выберите запись"
            }
            AppIconButton {
                visible: root.hasRecord && root.changeAllowed
                enabled: !root.busy
                glyph: Qt.resolvedUrl("../icons/pencil.svg")
                caption: "Изменить запись"
                onClicked: root.editRequested()
            }
            AppIconButton {
                visible: root.hasRecord && root.deleteAllowed
                enabled: !root.busy
                glyph: root.deleteIcon
                caption: root.deleteLabel
                onClicked: root.deleteRequested()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 9

                Repeater {
                    model: root.fields

                    delegate: ColumnLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 2

                        AppText { text: modelData.label; color: Theme.palette.muted }
                        AppText {
                            Layout.fillWidth: true
                            text: String(modelData.value ?? "—")
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
