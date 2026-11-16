import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl
import "../components"
import "../UserPresentation.js" as UsersUi

RecordsPage {
    resource: "roles"
    paginated: false
    rowLabel: row => UsersUi.roleLabel(row.name)
    details: row => [
        { label: "ID", value: row.id },
        { label: "Название роли", value: UsersUi.roleLabel(row.name) }
    ]
}
