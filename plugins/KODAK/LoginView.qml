import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import "CloudAPI.js" as CloudAPI

Item {
    id: loginView
    anchors.fill: parent
    width: 440
    height: 540

    signal logined(string sessionId)
    signal errorCatched(string error)

    onLogined: {
        pluginUtils.saveSession(sessionId)
        pluginRootWindow.hideBusy()
        pluginRootWindow.sessionId = sessionId
    }

    onErrorCatched: {
        pluginRootWindow.showMessage("Error: " + data["message"])
    }

    Image {
        anchors.fill: parent
        source: "res/background_login.gif"
    }

    TextField {
        id: loginField
        x: 65
        y: 256
        width: 310
        height: 31
        font.pixelSize: 18
        style: TextFieldStyle {
            textColor: "black"
            background: Rectangle {
                color: "white"
            }
        }

        Keys.onPressed: if (event.key === Qt.Key_Return) { loginBtn.clicked(); event.accepted = true; }
    }

    TextField {
        id: passwdField
        x: 65
        y: 319
        width: 310
        height: 30
        font.pixelSize: 18
        echoMode: TextInput.Password
        style: TextFieldStyle {
            textColor: "black"
            background: Rectangle {
                color: "white"
            }
        }

        Keys.onPressed: if (event.key === Qt.Key_Return) { loginBtn.clicked(); event.accepted = true; }
    }

    Button {
        id: cancelBtn
        width: 119
        height: 43
        x: 100
        y: 415

        style: ButtonStyle {
            background: Image {
                source: "res/cancel_btn.gif"
            }
        }

        onClicked: pluginRootWindow.close()
    }

    Button {
        id: loginBtn
        width: 119
        height: 43
        x: 220
        y: 415
        style: ButtonStyle {
            background: Image {
                source: "res/login.gif"
            }
        }

        onClicked: {
            if (loginField.text !== "" && passwdField.text !== "") {
                pluginRootWindow.showBusy()
                CloudAPI.login(loginField.text, passwdField.text, function(data) {
                    if (data["result"] === true) {
                        var session = data["message"]["session"]
                        loginView.logined(session)
                    } else {
                        loginView.errorCatced("Error: " + data["message"])
                    }
                })
            }
        }
    }
}
