import os
import json
from PyQt5.QtCore import (pyqtProperty, pyqtSignal, pyqtSlot, QObject, QUrl, QVariant, QFileInfo, QFile, QByteArray, QUuid, QStandardPaths)
from PyQt5.QtNetwork import (QNetworkAccessManager, QNetworkReply, QNetworkRequest)
from PyQt5.QtGui import QDesktopServices

from UM.Logger import Logger


class KodakUtils(QObject):

    def __init__(self, parent=None):
        super(KodakUtils, self).__init__(parent)
        self._filePath = ""
        self._cloudUrl = "https://cloud.3dprinteros.com/"
        #self._cloudUrl = "https://acorn.3dprinteros.com/"
        self._kodakUrl = "https://cloud.smart3d.tech/"
        #self._kodakUrl = "https://kodak-dev-acorn.3dprinteros.com/"
        self._appDataFolder = os.path.join(QStandardPaths.writableLocation(QStandardPaths.AppDataLocation), "KODAK")
        self._sessionFile = os.path.join(self._appDataFolder, "session")
        self._qnam = QNetworkAccessManager()
        self._qnam.finished.connect(self.finishedSlot)
        self._uploadData = None
        self._session = ""
        self._defaultFileName = ""

    uploadProgress = pyqtSignal(int, int)
    uploadFinished = pyqtSignal(QByteArray)
    uploadError = pyqtSignal(str)
    saveGCodeStarted = pyqtSignal(str)

    @pyqtProperty(str)
    def session(self):
        return self._sessionId

    @pyqtSlot(result=str)
    def cloudUrl(self):
        return self._cloudUrl

    @pyqtSlot(result=str)
    def kodakUrl(self):
        return self._kodakUrl

    @pyqtSlot(result=str)
    def defaultFileName(self):
        return self._defaultFileName

    @pyqtSlot(str)
    def setDefaultFileName(self, filename):
        self._defaultFileName = filename

    def construct_multipart(self, boundary, data, filepath):
        post_data = QByteArray()

        file = QFile(filepath)
        filename = QFileInfo(file.fileName()).fileName()
        file.open(QFile.ReadOnly)
        #create header for file
        post_data.insert(0, "--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\nContent-Type:application/octet-stream\r\n\r\n" % (boundary, filename))
        post_data.append(file.readAll())
        post_data.append("\r\n--%s--\r\n" % boundary)
        file.close()
        for key, value in data.items():
            post_data.append("\r\n")
            post_data.append("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s" % (boundary, key, value))

        #add footer
        post_data.append("\r\n--%s--\r\n" % boundary)
        return post_data

    def finishedSlot(self, reply):
        result = ""
        if reply.error() == 0:
            result = reply.readAll()
        else:
            result = '{ "result": false, "message": ' + reply.errorString() + '}'

        #reply.deleteLater()
        #print(result)
        self.uploadFinished.emit(result)
        os.remove(self._filePath)

    def uploadProgressSlot(self, bytes_sent, bytes_total):
        #print("uploadProgress")
        #print("%s / %s" % (bytes_sent, bytes_total))
        self.uploadProgress.emit(bytes_sent, bytes_total)

    @pyqtSlot(str, str)
    def saveUploadFile(self, fileName, data):
        fileName = fileName + ".gcode"
        self._uploadData = None
        self._uploadData = json.loads(data)
        self._filePath = os.path.join(self._appDataFolder, fileName)
        self.saveGCodeStarted.emit(self._filePath)

    def uploadFile(self):
        if os.path.isfile(self._filePath) is False:
            return

        url = self._cloudUrl + "apiglobal/upload"
        request = QNetworkRequest(QUrl(url))

        boundary = QUuid.createUuid().toByteArray().mid(1, 8)
        post_data = self.construct_multipart(boundary, self._uploadData, self._filePath)

        request.setHeader(QNetworkRequest.UserAgentHeader, "Cura Plugin")
        request.setHeader(QNetworkRequest.ContentLengthHeader, QVariant(post_data.length()))
        request.setHeader(QNetworkRequest.ContentTypeHeader,
                             'multipart/form-data; boundary=%s' % boundary)

        reply = self._qnam.post(request, post_data)
        reply.uploadProgress.connect(self.uploadProgressSlot)


    @pyqtSlot(str)
    def saveSession(self, session):
        self._session = session
        os.makedirs(self._appDataFolder, exist_ok=True)
        file = open(os.path.join(self._appDataFolder, "session"), "w")
        file.write(session)
        file.close()

    @pyqtSlot(result=str)
    def loadSession(self):
        os.makedirs(self._appDataFolder, exist_ok=True)

        if not os.path.exists(self._sessionFile):
            return ""

        file = open(self._sessionFile, "r")
        self._session = file.readline()
        file.close()
        return self._session

    @pyqtSlot()
    def clearSession(self):
        os.remove(self._sessionFile)
        self._session = ""

    @pyqtSlot(QUrl)
    def openUrl(self, url):
        QDesktopServices.openUrl(url)

    @pyqtSlot(str)
    def qmlLog(self, text):
        Logger.log("d", "3DPrinterOSUtils: %s", text)
