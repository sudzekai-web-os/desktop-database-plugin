import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl
import "../DatabaseApi.js" as Api

ColumnLayout {
    id: root
    required property string resource
    required property var rowLabel
    required property var details
    property var secondaryLabel: null
    property bool paginated: true
    property bool editable: false
    property bool changeAllowed: false
    property bool deleteAllowed: false
    property string deleteLabel: "Удалить"
    property url deleteIcon: Qt.resolvedUrl("../icons/trash.svg")
    property string deleteQuestion: "Удалить выбранную запись?"
    property var current: null
    property var rows: []
    property int offset: 0
    readonly property int pageSize: 50
    readonly property bool busy: request.busy
    readonly property string error: request.error
    signal editRequested(var record)

    PluginRequest { id: request }

    function load(keepSelection = true) {
        if (request.busy)
            return
        const selectedId = keepSelection ? current?.id : undefined
        current = null
        request.send("GET", Api.listPath(resource, paginated ? pageSize : 0, offset), {}, data => {
            const items = Api.records(data)
            if (items === null) {
                request.error = "Сервер вернул данные в неожиданном формате."
                return
            }
            rows = items
            if (paginated && !rows.length && offset > 0) {
                offset -= pageSize
                load()
                return
            }

            const selected = items.find(item => item.id === selectedId)
            if (selected)
                inspect(selected)
        })
    }

    function inspect(record) {
        current = null
        request.send("GET", Api.path(resource, record.id), {}, data => root.current = data)
    }

    function save(record, body, completed) {
        request.send(record ? "PUT" : "POST", Api.path(resource, record ? record.id : undefined), body, () => {
            completed()
            load()
        })
    }

    Component.onCompleted: load()

    RowLayout {
        AppIconButton {
            glyph: Qt.resolvedUrl("../icons/arrow-clockwise.svg")
            caption: "Обновить записи"
            enabled: !root.busy
            onClicked: root.load()
        }
        AppIconButton {
            glyph: Qt.resolvedUrl("../icons/plus-lg.svg")
            caption: "Создать запись"
            visible: root.editable
            enabled: !root.busy
            primary: true
            onClicked: root.editRequested(null)
        }
    }
    AppText {
        Layout.fillWidth: true
        visible: text !== ""
        color: Theme.palette.accent
        text: root.error
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    ResizableSplit {
        id: split
        Layout.fillWidth: true
        Layout.fillHeight: true

        AppCard {
            SplitView.fillWidth: true
            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 4
                model: root.rows
                delegate: DefaultButton {
                    id: button
                    required property var modelData
                    width: ListView.view.width
                    enabled: !root.busy
                    selected: root.current?.id === modelData.id
                    text: "#" + modelData.id + " · " + root.rowLabel(modelData)
                    contentItem: RowLayout {
                        AppText { Layout.fillWidth: true; text: button.text; textFormat: Text.PlainText; elide: Text.ElideRight }
                        AppText {
                            text: root.secondaryLabel ? root.secondaryLabel(button.modelData) : ""
                            textFormat: Text.PlainText
                            visible: text !== ""
                            color: Theme.palette.muted
                        }
                    }
                    onClicked: root.inspect(modelData)
                }
                ScrollBar.vertical: ScrollBar {}
            }
            AppText {
                anchors.centerIn: parent
                visible: root.rows.length === 0
                text: root.busy ? "Загрузка…" : "Нет записей"
            }
        }
        RecordDetails {
            SplitView.minimumWidth: split.minimumPanelWidth
            SplitView.maximumWidth: split.maximumPanelWidth
            SplitView.preferredWidth: Math.max(split.minimumPanelWidth, Math.floor(split.width * 0.42))
            hasRecord: root.current !== null
            recordTitle: root.current ? root.rowLabel(root.current) : ""
            fields: root.current ? root.details(root.current) : []
            busy: root.busy
            changeAllowed: root.changeAllowed
            deleteAllowed: root.deleteAllowed
            deleteLabel: root.deleteLabel
            deleteIcon: root.deleteIcon
            onEditRequested: root.editRequested(root.current)
            onDeleteRequested: confirmation.open()
        }
    }
    RowLayout {
        visible: root.paginated
        AppIconButton {
            glyph: Qt.resolvedUrl("../icons/chevron-left.svg")
            caption: "Предыдущая страница"
            enabled: !root.busy && root.offset > 0
            onClicked: { root.offset -= root.pageSize; root.load(false) }
        }
        AppText { text: "Страница " + (root.offset / root.pageSize + 1) }
        AppIconButton {
            glyph: Qt.resolvedUrl("../icons/chevron-right.svg")
            caption: "Следующая страница"
            enabled: !root.busy && root.rows.length === root.pageSize
            onClicked: { root.offset += root.pageSize; root.load(false) }
        }
    }
    AppDialog {
        id: confirmation
        title: root.deleteLabel
        acceptText: root.deleteLabel
        cancelText: "Отмена"
        description: root.deleteQuestion
        onAccepted: if (root.deleteAllowed && root.current)
            request.send("DELETE", Api.path(root.resource, root.current.id), {}, () => root.load())
    }
}
