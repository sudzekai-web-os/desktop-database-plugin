import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl

Item {
    id: root

    property string section: "users"
    property string version: ""
    property string pending: ""
    property string operation: ""
    property string error: ""
    property var rows: []
    property var current: null
    property int offset: 0
    readonly property int pageSize: 50
    readonly property bool paginated: section !== "roles"
    readonly property bool canEdit: Session.administrator && section !== "roles"
    readonly property bool busy: pending !== ""

    function send(method, route, body, next) {
        if (busy)
            return
        error = ""
        operation = next
        pending = Session.request(method, "/database/" + route, body)
        if (!busy)
            error = "Войдите на сервер, чтобы выполнить запрос."
    }

    function list() {
        current = null
        send("GET", section + (paginated ? "?limit=" + pageSize + "&offset=" + offset : ""), {}, "list")
    }

    function select(next) {
        if (busy || next === section)
            return
        section = next
        offset = 0
        rows = []
        list()
    }

    function rowLabel(row) {
        if (section === "users")
            return row.username
        if (section === "roles")
            return row.name
        return row.action + " · " + row.dateTime
    }

    function detailText(row) {
        if (!row)
            return ""
        if (section === "users" || section === "roles")
            return "ID: " + row.id + "\n" + rowLabel(row)
        return "ID: " + row.id + "\nПользователь: " + row.userId + "\nВремя UTC: "
            + row.dateTime + "\nДействие: " + row.action + "\n" + row.summary
    }

    Component.onCompleted: {
        if (Session.authenticated)
            send("GET", "version", {}, "version")
    }

    Connections {
        target: Session
        function onRequestFinished(id, status, data, message) {
            if (id !== root.pending)
                return
            const action = root.operation
            root.pending = ""
            root.error = message
            if (message) {
                if (action === "version" && status !== 401) {
                    root.list()
                }
                return
            }
            if (action === "version") {
                root.version = String(data)
                root.list()
            } else if (action === "list") {
                root.rows = data
                if (!root.rows.length && root.offset > 0) {
                    root.offset -= root.pageSize
                    root.list()
                }
            } else if (action === "detail") {
                root.current = data
            } else {
                editor.close()
                root.list()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        SectionHeading {
            Layout.fillWidth: true
            title: "База данных"
            description: root.version ? "Версия плагина " + root.version : ""
        }

        AppText {
            visible: !Session.authenticated
            text: "Подключитесь к серверу и войдите, чтобы открыть базу данных."
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Session.authenticated
            Repeater {
                model: [
                    { key: "users", name: "Пользователи" },
                    { key: "roles", name: "Роли" },
                    { key: "history", name: "История" }
                ]
                DefaultButton {
                    required property var modelData
                    text: modelData.name
                    primary: root.section === modelData.key
                    enabled: !root.busy
                    onClicked: root.select(modelData.key)
                }
            }
            Item { Layout.fillWidth: true }
            DefaultButton {
                text: "Обновить"
                enabled: !root.busy
                onClicked: root.list()
            }
            DefaultButton {
                visible: root.canEdit
                enabled: !root.busy
                primary: true
                text: "Создать"
                onClicked: { root.error = ""; editor.start(root.section, null) }
            }
        }

        AppText {
            visible: root.error !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.palette.accent
            text: root.error
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Session.authenticated
            spacing: 16

            AppCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: root.rows
                    spacing: 4
                    delegate: DefaultButton {
                        required property var modelData
                        width: ListView.view.width
                        enabled: !root.busy
                        text: "#" + modelData.id + " · " + root.rowLabel(modelData)
                        onClicked: root.send("GET", root.section + "/" + modelData.id, {}, "detail")
                    }
                    ScrollBar.vertical: ScrollBar {}
                }
                AppText {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    text: root.busy ? "Загрузка…" : "Нет записей"
                }
            }

            AppCard {
                Layout.preferredWidth: Math.min(320, root.width * 0.43)
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10
                    AppText {
                        Layout.fillWidth: true
                        text: root.current ? "Подробности" : "Выберите запись"
                        font.bold: true
                    }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        AppText {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: root.detailText(root.current)
                        }
                    }
                    RowLayout {
                        visible: root.canEdit && root.current !== null
                        DefaultButton {
                            text: "Изменить"
                            enabled: !root.busy
                            onClicked: { root.error = ""; editor.start(root.section, root.current) }
                        }
                        DefaultButton {
                            text: "Удалить"
                            enabled: !root.busy
                            onClicked: confirmation.open()
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: Session.authenticated && root.paginated
            DefaultButton {
                text: "Назад"
                enabled: !root.busy && root.offset > 0
                onClicked: { root.offset -= root.pageSize; root.list() }
            }
            AppText { text: "Страница " + (root.offset / root.pageSize + 1) }
            DefaultButton {
                text: "Далее"
                enabled: !root.busy && root.rows.length === root.pageSize
                onClicked: { root.offset += root.pageSize; root.list() }
            }
        }
    }

    RecordEditor {
        id: editor
        anchors.centerIn: Overlay.overlay
        busy: root.busy
        serverError: root.error
        onSubmitted: (record, body) => root.send(record ? "PUT" : "POST",
                                                root.section + (record ? "/" + record.id : ""), body, "change")
    }

    Dialog {
        id: confirmation
        anchors.centerIn: Overlay.overlay
        title: "Удаление записи"
        modal: true
        standardButtons: Dialog.Yes | Dialog.Cancel
        AppText { text: "Удалить выбранную запись?" }
        onAccepted: {
            if (root.current)
                root.send("DELETE", root.section + "/" + root.current.id, {}, "change")
        }
    }
}
