import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1
import QtQml 2.2

import "CloudAPI.js" as CloudAPI

Window {
    id: pluginRootWindow
    visible: false
    width: 440
    height: 540
    modality: Qt.ApplicationModal
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height

    title: qsTr("3DPrinterOS Plugin")

    property string sessionId: ""
    property bool optionVisible: true
    property string uploadStatus: "upload" // good bad
    property string fileId: ""
    property string printerTypeId: ""

    onClosing: {
        optionVisible = true
        fileId = ""
        uploadStatus = "upload"
    }

    function showBusy() {
        busyLayer.visible = true
    }

    function hideBusy() {
        busyLayer.visible = false
    }

    function showMessage(text) {
        msgDialog.text = text;
        msgDialog.visible = true
    }

    Timer {
        interval: 100
        repeat: false
        running: true
        onTriggered: {
            var loadedSession = pluginUtils.loadSession()
            pluginUtils.qmlLog("loadedSession: " + loadedSession)
            if (loadedSession !== "") {
                showBusy()
                CloudAPI.checkSession(loadedSession, function(data) {
                    hideBusy()
                    if (data["result"] === true) {
                        pluginRootWindow.sessionId = loadedSession
                    }
                    pluginRootWindow.visible = true
                })
            }
        }
    }

    MessageDialog {
        id: msgDialog
        title: "Error"

        onAccepted: {
            msgDialog.visible = false
        }
    }

    Rectangle {
        id: rootRect
        anchors.fill: parent

        Rectangle {
            id: busyLayer
            anchors.fill: parent
            color: "black"
            opacity: 0.5
            visible: false
            z: 100
            BusyIndicator {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.25
                height: Math.min(parent.width, parent.height) * 0.25
                running: parent.visible
            }

            MouseArea {
                anchors.fill: parent
            }
        }

        Loader {
            id: bodyLoader
            anchors.fill: parent
            source: sessionId === "" ? "LoginView.qml" : "OptionsView.qml"
        }
    }

    Component.onCompleted: {
        setX(Screen.width / 2 - width / 2);
        setY(Screen.height / 2 - height / 2);
    }
}
