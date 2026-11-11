import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl

Dialog {
    id: root
    property string section: "users"
    property var record: null
    property bool busy: false
    property string validationError: ""
    property string serverError: ""
    readonly property bool user: section === "users"
    signal submitted(var record, var body)

    title: record ? "Изменение записи" : "Создание записи"
    modal: true
    width: 440
    closePolicy: busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    onClosed: password.clear()

    function start(next, item) {
        section = next
        record = item
        validationError = ""
        username.text = item && user ? item.username : ""
        password.clear()
        role.currentIndex = -1
        blocked.currentIndex = 0
        userId.text = item && !user ? String(item.userId) : ""
        date.text = item && !user ? item.dateTime : ""
        action.text = item && !user ? item.action : ""
        summary.text = item && !user ? item.summary : ""
        open()
    }

    function submit() {
        validationError = ""
        if (user) {
            if (!username.text.trim() || role.currentIndex < 0 || (!record && !password.text)) {
                validationError = "Укажите имя, роль и пароль нового пользователя."
                return
            }
            const body = { username: username.text.trim(), roleId: role.currentValue }
            if (password.text)
                body.password = password.text
            if (blocked.currentIndex > 0)
                body.isBlocked = blocked.currentIndex === 2
            submitted(record, body)
            password.clear()
        } else {
            const id = Number(userId.text)
            if (!/^[1-9][0-9]*$/.test(userId.text) || !Number.isSafeInteger(id) || !action.text.trim() || !summary.text.trim()) {
                validationError = "Укажите ID пользователя, действие и описание."
                return
            }
            const body = { userId: id, action: action.text.trim(), summary: summary.text.trim() }
            if (date.text.trim()) {
                const value = date.text.trim()
                if (!/Z$/i.test(value) || isNaN(Date.parse(value))) {
                    validationError = "Укажите время в UTC, например 2026-11-12T10:30:00Z."
                    return
                }
                body.dateTime = value
            }
            submitted(record, body)
        }
    }

    contentItem: ColumnLayout {
        spacing: 8
        AppField { id: username; visible: root.user; Layout.fillWidth: true; placeholderText: "Имя пользователя" }
        AppField {
            id: password
            visible: root.user
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: root.record ? "Новый пароль (необязательно)" : "Пароль"
        }
        AppComboBox {
            id: role
            visible: root.user
            Layout.fillWidth: true
            textRole: "label"
            valueRole: "id"
            model: [
                { id: 4, label: "Наблюдатель" },
                { id: 2, label: "Пользователь" },
                { id: 1, label: "Администратор" }
            ]
            displayText: currentIndex < 0 ? "Выберите роль" : currentText
        }
        AppComboBox {
            id: blocked
            visible: root.user
            Layout.fillWidth: true
            model: [root.record ? "Сохранить состояние блокировки" : "По умолчанию", "Активен", "Заблокирован"]
        }
        AppField { id: userId; visible: !root.user; Layout.fillWidth: true; placeholderText: "ID пользователя" }
        AppField { id: date; visible: !root.user; Layout.fillWidth: true; placeholderText: "Время UTC (необязательно)" }
        AppField { id: action; visible: !root.user; Layout.fillWidth: true; placeholderText: "Действие" }
        TextArea {
            id: summary
            visible: !root.user
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            wrapMode: TextEdit.Wrap
            placeholderText: "Описание"
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
            DefaultButton { text: "Сохранить"; primary: true; enabled: !root.busy; onClicked: root.submit() }
        }
    }
}
