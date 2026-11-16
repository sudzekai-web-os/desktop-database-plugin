import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl

AppDialog {
    id: root
    preferredWidth: 440
    title: record ? "Изменение пользователя" : "Создание пользователя"

    property var record: null
    property string validationError: ""
    property string serverError: ""

    signal submitted(var record, var body)

    onClosed: password.clear()

    function start(item) {
        record = item
        validationError = ""
        username.text = item ? item.username : ""
        password.clear()
        role.currentIndex = item && item.roleId ? role.indexOfValue(item.roleId) : -1
        blocked.currentIndex = 0
        open()
    }

    function submit() {
        validationError = ""
        if (!username.text.trim() || role.currentIndex < 0 || (!record && !password.text)) {
            validationError = record ? "Укажите имя и роль пользователя." : "Укажите имя, роль и пароль нового пользователя."
            return
        }
        const body = { username: username.text.trim(), roleId: role.currentValue }
        if (password.text)
            body.password = password.text
        if (blocked.currentValue !== 0)
            body.isBlocked = blocked.currentValue === 2
        submitted(record, body)
        password.clear()
    }

    contentItem: ColumnLayout {
        spacing: 10
        AppField { id: username; Layout.fillWidth: true; placeholderText: "Имя пользователя" }
        AppField {
            id: password
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: root.record ? "Новый пароль (необязательно)" : "Пароль"
        }
        AppComboBox {
            id: role
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
            Layout.fillWidth: true
            textRole: "label"
            valueRole: "value"
            model: root.record ? [
                { label: root.record.isBlocked ? "Сохранить блокировку" : "Сохранить активный статус", value: 0 },
                { label: "Разблокировать", value: 1 },
                { label: "Заблокировать", value: 2 }
            ] : [
                { label: "Аккаунт активен", value: 1 },
                { label: "Аккаунт заблокирован", value: 2 }
            ]
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
