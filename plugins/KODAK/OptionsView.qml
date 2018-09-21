import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.1

import Cura 1.0 as Cura

import "CloudAPI.js" as CloudAPI

Item {
    id: sendViewRoot
    anchors.fill: parent
    width: 440
    height: 540

    property var projectsComboBoxModel: []
    property var printerTypeComboBoxModel: []

    function initProjectList() {
        var i = 0
        pluginRootWindow.showBusy()
        CloudAPI.getProjects(pluginRootWindow.sessionId, function(data) {
            if (data["result"] === true) {
                projectsComboBoxModel = data["message"]
                comboBox.currentIndex = -1
                comboBox.editText = ""
            } else {
                pluginRootWindow.showMessage("Error: " + data["message"])
            }
            pluginRootWindow.hideBusy()
        })

        CloudAPI.getPrinterTypes(pluginRootWindow.sessionId, function(data) {
            pluginUtils.qmlLog(JSON.stringify(data))
        })
    }

    function initPrinterTypeList() {
        var i = 0
        pluginRootWindow.showBusy()
        CloudAPI.getPrinterTypes(pluginRootWindow.sessionId, function(data) {
            pluginRootWindow.hideBusy()
            if (data["result"] === true) {
                var printerTypeFounded = false
                printerTypeComboBoxModel = data["message"]
                if (printerTypeComboBoxModel.length > 0) {
                    //var printerType = Cura.MachineManager.activeMachineId.split(' #')[0];
                    //printerType += (printerType === "Dremel 3D45" || printerType === "Dremel 3D40") ? " Idea Builder" : ""
					var printerType = "KODAK Portrait"
                    for (var i = 0; i < printerTypeComboBoxModel.length; i++) {
                        if (printerTypeComboBoxModel[i]["description"] === printerType) {
							// pluginRootWindow.showMessage(JSON.stringify(printerTypeComboBoxModel[i]))
                            printerTypeBox.currentIndex = i
                            printerTypeFounded = true
                        }
                    }

                    if (!printerTypeFounded) {
                        printerTypeBox.currentIndex = -1
                        pluginRootWindow.showMessage("Warning: Selected printer (" + printerType + ") not found in the printer list for upload.")
                    }
                }
            } else {
                pluginRootWindow.showMessage("Error: " + data["message"])
            }
        })
    }

    function finished(dataStr) {
        var data = JSON.parse(dataStr)
        if (data["result"] === false) {
            pluginRootWindow.showMessage("Error. " + data["message"])
            pluginRootWindow.uploadStatus = "bad"
            return
        }

       // pluginRootWindow.uploadStatus = "good"
        pluginRootWindow.fileId = data["message"]["file_id"]
        CloudAPI.updateFile(pluginRootWindow.sessionId, pluginRootWindow.fileId, pluginRootWindow.printerTypeId, "Cura",  false, function(updateData) {
            if (updateData["result"] === true) {
                pluginRootWindow.uploadStatus = "good"
            } else {
                pluginRootWindow.showMessage("Error updateFile. " + updateData["message"])
                pluginRootWindow.uploadStatus = "bad"
            }
        })
    }

    function progress(sent, total) {
        if (total > 0) {
            progressBar.value = sent / total * 100
        }
    }

    Image {
        anchors.fill: parent
        source: "res/background_ok.gif"

        Item {
            id: optionView
            anchors.fill: parent
            visible: pluginRootWindow.optionVisible

            onVisibleChanged: {
                fileNameField.text = pluginUtils.defaultFileName() 
            }

            Text {
                id: fileNameLabel
                x: 24
                y: 79
                width: 73
                height: 19
                text: qsTr("File name")
                font.pixelSize: 13
            }

            TextField {
                id: fileNameField
                x: 24
                y: 104
                width: 392
                height: 31
                text: pluginUtils.defaultFileName()
                font.pixelSize: 18
                style: TextFieldStyle {
                    textColor: "black"
                    background: Rectangle {
                        color: "white"
                        border {
                            width: 1
                            color: "#d1c9c6"
                        }
                    }
                }

                Component.onCompleted: {
                    fileNameField.text = pluginUtils.defaultFileName()
                    pluginUtils.qmlLog("defaultFileName: " + fileNameField.text)
                }
            }

            Text {
                id: printerTypeLabel
                x: 24
                y: 147
                width: 73
                height: 19
                text: qsTr("Printer type")
                font.pixelSize: 13
            }

            ComboBox {
                id: printerTypeBox
                x: 24
                y: 172
                width: 392
                height: 32
                currentIndex: -1
                textRole: 'description'
                editText: ""
				enabled: false
                model: printerTypeComboBoxModel
            }

            Text {
                id: projectNameLabel
                x: 24
                y: 247
                width: 73
                height: 19
                text: qsTr("Project Name")
                visible: projectRadio.checked
                font.pixelSize: 13
            }

            ComboBox {
                id: comboBox
                x: 24
                y: 272
                width: 392
                height: 32
                currentIndex: -1
                textRole: 'name'
                visible: projectRadio.checked
                editable: true
                editText: ""
                model: projectsComboBoxModel
            }

            RadioButton {
                id: singleRadio
                x: 24
                y: 214
                text: qsTr("Single File")
                checked: true
                onClicked: {
                    projectRadio.checked = !checked
                }
            }

            RadioButton {
                id: projectRadio
                x: 286
                y: 214
                checked: false
                text: qsTr("Project file")
                onClicked: {
                    singleRadio.checked = !checked
                    initProjectList()
                }
            }

            Button {
                id: cancelBtn
                x: 32
                y: 470
                style: ButtonStyle {
                    background: Image {
                        source: "res/cancel_btn.gif"
                    }
                }
                onClicked: pluginRootWindow.close()
            }

            Button {
                id: logoutBtn
                x: 158
                y: 470
                style: ButtonStyle {
                    background: Image {
                        source: "res/logout.gif"
                    }
                }

                onClicked: {
                    pluginRootWindow.showBusy()
                    CloudAPI.logout(pluginRootWindow.sessionId, function(data) {
                        if (data["result"] === false) {
                            pluginRootWindow.showMessage("Error. " + data["message"])
                        }
                        pluginRootWindow.sessionId = ""
                        pluginUtils.clearSession()
                        pluginRootWindow.hideBusy()
                    })
                }
            }

            Button {
                id: uploadBtn

                x: 289
                y: 470

                style: ButtonStyle {
                    background: Image {
                        source: "res/upload_btn.gif"
                    }
                }

                onClicked: {
                    var fileName = fileNameField.text, projectName = "", projectId = "", projectColor = "", printerType = ""
                    if (fileName === "") {
                        pluginRootWindow.showMessage("Error. File name is empty")
                        return
                    }
                    
                    //*, "", | , :
                    
                    if (fileName.indexOf(":") !== -1 || fileName.indexOf('"') !== -1  || fileName.indexOf("|") !== -1 || fileName.indexOf("*") !== -1) {
                        pluginRootWindow.showMessage("Error. File name can't contain \*, \"\", | , : symbols")
                        return
                    }

                    if (printerTypeBox.currentIndex === -1) {
                        pluginRootWindow.showMessage("Error. Select printer type")
                        return
                    }

                    printerType = printerTypeComboBoxModel[printerTypeBox.currentIndex]["id"]

                    if (comboBox.visible) {
                        if (comboBox.editText === "") {
                            pluginRootWindow.showMessage("Error. Project name is empty")
                            return
                        }
                        if (comboBox.currentIndex !== -1 && projectsComboBoxModel[comboBox.currentIndex]["name"] === comboBox.editText) {
                            projectName = projectsComboBoxModel[comboBox.currentIndex]["name"]
                            projectId = projectsComboBoxModel[comboBox.currentIndex]["id"]
                            projectColor = projectsComboBoxModel[comboBox.currentIndex]["color"]
                        } else {
                            projectName = comboBox.editText
                            projectId = ""
                            projectColor = "grey"
                        }
                    }

                    pluginRootWindow.printerTypeId = printerType

                    var uploadData = {}
                    uploadData["gtype"] = "Cura"
                    uploadData["ptype"] = printerType
                    uploadData["zip"] = false
                    uploadData["session"] = pluginRootWindow.sessionId
                    if (projectId.length > 0) {
                        uploadData["project_id"] = projectId
                    } else if (projectName.length > 0) {
                        uploadData["project_name"] = projectName
                        uploadData["project_color"] = "grey"
                    }

                    pluginUtils.uploadProgress.disconnect(progress)
                    pluginUtils.uploadFinished.disconnect(finished)
                    pluginUtils.uploadProgress.connect(progress)
                    pluginUtils.uploadFinished.connect(finished)
                    pluginUtils.saveUploadFile(fileName, JSON.stringify(uploadData))
                    pluginRootWindow.optionVisible = false
                }
            }
        }

        Item {
            id: uploadView
            anchors.fill: parent
            visible: !pluginRootWindow.optionVisible

            Rectangle {
                id: rectangle
                y: 109
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100
                height: 100
                color: pluginRootWindow.uploadStatus === "upload" ? "#e6e6e6" : "white"
                radius: width / 2
                Image {
                    id: statusImg
                    anchors.centerIn: parent
                    width: parent.width * 0.7
                    height: parent.width * 0.7
                    source: switch (pluginRootWindow.uploadStatus) {
                            case "bad":
                                return "res/bad.gif"
                            case "good":
                                return "res/ok.gif"
                            }
                    visible: pluginRootWindow.uploadStatus !== "upload"
                }

                BusyIndicator {
                    id: busy
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    visible: pluginRootWindow.uploadStatus === "upload"
                }
            }

            ProgressBar {
                id: progressBar
                x: 20
                y: 271
                width: 400
                height: 11
                minimumValue: 0
                maximumValue: 100
                visible: pluginRootWindow.uploadStatus === "upload"
                value: 0
                style: ProgressBarStyle {
                        background: Rectangle {
                            radius: 2
                            color: "white"
                            border.color: "gray"
                            border.width: 1
                        }

                        progress: Rectangle {
                            color: "#ffaa00"
                            border.color: "gray"
                            border.width: 1
                        }
                }
            }

            Label {
                id: label
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: progressBar.top
                    bottomMargin: 5
                }

                font.pixelSize: progressBar.height * 1.5
                text: switch(pluginRootWindow.uploadStatus) {
                      case "upload":
                          return qsTr("Please wait while file is uploading ...")
                      case "bad":
                          return qsTr("Error uploading file!")
                      case "good":
                          return qsTr("File is uploaded!")
                }
            }

            Item {
                id: buttonsSet
                anchors.fill: parent
                visible: pluginRootWindow.uploadStatus !== "upload"

                Button {
                    id: closeBtn
                    x: 70
                    y: 347

                    style: ButtonStyle {
                        background: Image {
                            source: "res/close.gif"
                        }
                    }

                    onClicked: pluginRootWindow.close()
                }

                Button {
                    id: cloudBtn
                    x: 70
                    y: 296
                    style: ButtonStyle {
                        background: Image {
                            source: "res/gotocloud.gif"
                        }
                    }

                    onClicked: {
                        CloudAPI.getAuthToken(pluginRootWindow.sessionId, function(data) {
                            console.log(JSON.stringify(data));
                            var url = pluginUtils.kodakUrl() + "myfiles";
                            if (data["result"] === true) {
                                url = pluginUtils.kodakUrl() + "noauth/login_with_auth_token/" + data["message"];
                            }
                            pluginUtils.openUrl(url)
                        })
                    }
                }

                Button {
                    id: printBtn
                    x: 237
                    y: 297
                    style: ButtonStyle {
                        background: Image {
                            source: "res/knopka_print.gif"
                        }
                    }

                    onClicked: {
                        CloudAPI.getAuthToken(pluginRootWindow.sessionId, function(data) {
                            var url = pluginUtils.kodakUrl() + "myfiles#app=print;id=" + pluginRootWindow.fileId
                            if (data["result"] === true) {
                                url = pluginUtils.kodakUrl() + "noauth/login_with_auth_token/" + data["message"] + "?redirect_url=" + encodeURIComponent("myfiles#app=print;id=" + pluginRootWindow.fileId);
                            }
                            pluginUtils.openUrl(url)
                        })
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        initPrinterTypeList()
    }
}
