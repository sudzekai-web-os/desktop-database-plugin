import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl

AppDialog {
    id: root
    preferredWidth: 440
    title: record ? "Изменение записи истории" : "Создание записи истории"

    property var record: null
    property string validationError: ""
    property string serverError: ""

    signal submitted(var record, var body)

    function start(item) {
        record = item
        validationError = ""
        userId.text = item ? String(item.userId) : ""
        date.text = item ? item.dateTime : ""
        action.text = item ? item.action : ""
        summary.text = item ? item.summary : ""
        open()
    }

    function submit() {
        validationError = ""
        const id = Number(userId.text)
        if (!/^[1-9][0-9]*$/.test(userId.text) || !Number.isSafeInteger(id) || !action.text.trim() || !summary.text.trim()) {
            validationError = "Укажите ID пользователя, действие и описание."
            return
        }
        const body = { userId: id, action: action.text.trim(), summary: summary.text.trim() }
        const value = date.text.trim()
        if (value) {
            if (!/Z$/i.test(value) || isNaN(Date.parse(value))) {
                validationError = "Укажите время в UTC, например 2026-11-12T10:30:00Z."
                return
            }
            body.dateTime = value
        }
        submitted(record, body)
    }

    contentItem: ColumnLayout {
        spacing: 10
        AppField { id: userId; Layout.fillWidth: true; placeholderText: "ID пользователя" }
        AppField { id: date; Layout.fillWidth: true; placeholderText: "Время UTC (необязательно)" }
        AppField { id: action; Layout.fillWidth: true; placeholderText: "Действие" }
        TextArea {
            id: summary
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            padding: 10
            wrapMode: TextEdit.Wrap
            color: Theme.palette.ink
            placeholderTextColor: Theme.palette.muted
            selectionColor: Theme.palette.accent
            selectedTextColor: Theme.palette.onAccent
            placeholderText: "Описание"
            background: Rectangle {
                radius: 8
                color: Theme.palette.surface
                border.color: summary.activeFocus ? Theme.palette.accent : Theme.palette.line
            }
        }
        AppText {
            Layout.fillWidth: true
            visible: text !== ""
            wrapMode: Text.WordWrap
            color: Theme.palette.accent
            text: root.validationError || root.serverError
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            DefaultButton { text: "Отмена"; enabled: !root.busy; onClicked: root.close() }
            DefaultButton { text: root.record ? "Сохранить" : "Создать"; primary: true; enabled: !root.busy; onClicked: root.submit() }
        }
    }
}
