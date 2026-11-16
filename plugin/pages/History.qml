import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl
import "../components"

RecordsPage {
    id: root
    resource: "history"
    editable: AccountSession.administrator
    changeAllowed: editable && current !== null
    deleteAllowed: changeAllowed
    rowLabel: row => row.action
    secondaryLabel: row => (row.dateTime || "").replace("T", " ")
    details: row => [
        { label: "ID", value: row.id },
        { label: "ID пользователя", value: row.userId },
        { label: "Время (UTC)", value: row.dateTime },
        { label: "Описание", value: row.summary }
    ]

    onEditRequested: record => editor.start(record)
    HistoryEditor {
        id: editor
        busy: root.busy
        serverError: root.error
        onSubmitted: (record, body) => root.save(record, body, () => editor.close())
    }
}
