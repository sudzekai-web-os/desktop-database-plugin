import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import linctrl
import "pages"

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 24
    spacing: 12

    property string version: ""
    property int tab: 0

    PluginRequest { id: versionRequest }

    function loadVersion() {
        if (AccountSession.authenticated)
            versionRequest.send("GET", "/database/version", {}, data => root.version = String(data))
        else
            version = ""
    }

    Component.onCompleted: loadVersion()
    Connections {
        target: AccountSession
        function onAuthenticatedChanged() { root.loadVersion() }
    }

    SectionHeading {
        Layout.fillWidth: true
        title: "База данных"
        description: root.version ? "Версия плагина " + root.version : ""
    }
    AppText {
        visible: !AccountSession.authenticated
        text: "Войдите на сервер, чтобы открыть базу данных."
    }
    RowLayout {
        visible: AccountSession.authenticated
        Repeater {
            model: ["Пользователи", "Роли", "История"]
            DefaultButton {
                required property int index
                required property string modelData
                text: modelData
                primary: index === root.tab
                onClicked: root.tab = index
            }
        }
    }
    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: AccountSession.authenticated
        sourceComponent: root.tab === 0 ? users : root.tab === 1 ? roles : history
    }
    Component { id: users; Users { version: root.version } }
    Component { id: roles; Roles {} }
    Component { id: history; History {} }
}
