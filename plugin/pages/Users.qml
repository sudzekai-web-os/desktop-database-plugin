import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl
import "../components"
import "../UserPresentation.js" as UsersUi

RecordsPage {
    id: root
    required property string version
    resource: "users"
    editable: AccountSession.administrator
    changeAllowed: editable && current !== null
        && String(current.id) !== AccountSession.userId && String(current.username).toLowerCase() !== "linctrl_user"
    deleteAllowed: changeAllowed && current.isBlocked !== true && UsersUi.supportsBlocking(version)
    deleteLabel: "Заблокировать"
    deleteIcon: Qt.resolvedUrl("../icons/lock-fill.svg")
    deleteQuestion: "Заблокировать выбранного пользователя?"
    rowLabel: row => row.username
    secondaryLabel: row => UsersUi.roleLabel(row.roleName)
    details: row => [
        { label: "ID", value: row.id },
        { label: "Роль", value: UsersUi.roleLabel(row.roleName) || "—" },
        { label: "Статус", value: row.isBlocked === true ? "Заблокирован" : row.isBlocked === false ? "Активен" : "—" }
    ]

    onEditRequested: record => editor.start(record)
    UserEditor {
        id: editor
        busy: root.busy
        serverError: root.error
        onSubmitted: (record, body) => root.save(record, body, () => editor.close())
    }
}
