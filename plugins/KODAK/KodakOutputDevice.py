# Copyright (c) 2018 3DPrinterOS

import os
import os.path
import sys

from .KodakUtils import KodakUtils
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.QtNetwork import *
from PyQt5.QtQml import *
from PyQt5.QtQuick import (QQuickView)

# from PyQt5.QtGui import QDesktopServices
# from PyQt5.QtCore import pyqtProperty, pyqtSignal, Qt, QUrl, QObject, QVariant, QStandardPaths #To define a shortcut key and to find the QML files, and to expose information to QML.
# from PyQt5.QtQml import QQmlComponent, QQmlContext, QQmlApplicationEngine #To create a dialogue window.

from UM.Application import Application  # To register the information dialogue.
from UM.Preferences import Preferences

from UM.Logger import Logger
from UM.Mesh.MeshWriter import MeshWriter
from UM.FileHandler.WriteFileJob import WriteFileJob
from UM.Message import Message
from UM.MimeTypeDatabase import MimeType
from UM.PluginRegistry import PluginRegistry  # To find the QML files in the plug-in folder.

from UM.OutputDevice.OutputDevice import OutputDevice
from UM.OutputDevice import OutputDeviceError
from UM.Platform import Platform

from UM.i18n import i18nCatalog

catalog = i18nCatalog("cura")


##  Implements an OutputDevice that supports saving to arbitrary local files.
class KodakOutputDevice(OutputDevice):
    def __init__(self, pluginId):
        super().__init__("kodak")

        self._pluginId = pluginId
        self.setName(catalog.i18nc("@item:inmenu", "Local File"))
        self.setShortDescription(
            catalog.i18nc("@action:button", "Upload"))
        self.setDescription(catalog.i18nc("@info:tooltip", "Upload to KODAK 3D printing Cloud"))
        self.setIconName("upload_3d")
        self.pluginUtils = KodakUtils()
        self.pluginUtils.saveGCodeStarted.connect(self.saveGCode)
        self.plugin_window = None
        self._nodes = None
        self._writing = False

    ##  Request the specified nodes to be written to a file.
    #
    #   \param nodes A collection of scene nodes that should be written to the
    #   file.
    #   \param file_name \type{string} A suggestion for the file name to write
    #   to. Can be freely ignored if providing a file name makes no sense.
    #   \param limit_mimetypes Should we limit the available MIME types to the
    #   MIME types available to the currently active machine?
    #   \param kwargs Keyword arguments.

    def requestWrite(self, nodes, file_name=None, limit_mimetypes=None, file_handler=None, **kwargs):
        if self._writing:
            raise OutputDeviceError.DeviceBusyError()

        # Set default file name
        self.pluginUtils.setDefaultFileName(file_name)

        self._nodes = None
        self._nodes = nodes
        if self.plugin_window is not None:
            self.plugin_window = None

        # Set up and display file dialog
        self.plugin_window = self._createDialogue()

        self.plugin_window.show()

    ##  Creates a modal dialogue
    def _createDialogue(self):
        qml_file = QUrl.fromLocalFile(
            os.path.join(PluginRegistry.getInstance().getPluginPath(self._pluginId), "PluginMain.qml"))
        component = QQmlComponent(Application.getInstance()._qml_engine, qml_file)

        Application.getInstance()._qml_engine.rootContext().setContextProperty("pluginUtils", self.pluginUtils)

        return component.create()

    def saveGCode(self, file_name):
        self.writeStarted.emit(self)

        file_writer = Application.getInstance().getMeshFileHandler().getWriter("GCodeWriter")
        Logger.log("d", "Writing GCode to %s", file_name)
        stream = open(file_name, "wt", encoding="utf-8")

        try:
            job = WriteFileJob(file_writer, stream, self._nodes, MeshWriter.OutputMode.TextMode)
            job.setFileName(file_name)
            job.progress.connect(self._onJobProgress)
            job.finished.connect(self._onWriteJobFinished)

            message = Message(catalog.i18nc("@info:progress Don't translate the XML tags <filename>!",
                                            "Saving to <filename>{0}</filename>").format(file_name),
                              0, False, -1, catalog.i18nc("@info:title", "Saving"))
            message.show()

            job.setMessage(message)
            self._writing = True
            job.start()
        except PermissionError as e:
            Logger.log("e", "Permission denied when trying to write to %s: %s", file_name, str(e))
            raise OutputDeviceError.PermissionDeniedError(
                catalog.i18nc("@info:status Don't translate the XML tags <filename>!",
                              "Permission denied when trying to save <filename>{0}</filename>").format(
                    file_name)) from e
        except OSError as e:
            Logger.log("e", "Operating system would not let us write to %s: %s", file_name, str(e))
            raise OutputDeviceError.WriteRequestFailedError(
                catalog.i18nc("@info:status Don't translate the XML tags <filename> or <message>!",
                              "Could not save to <filename>{0}</filename>: <message>{1}</message>").format()) from e

    def _onJobProgress(self, job, progress):
        self.writeProgress.emit(self, progress)

    def _onWriteJobFinished(self, job):
        self._writing = False
        self.writeFinished.emit(self)
        if job.getResult():
            self.writeSuccess.emit(self)
            self.pluginUtils.uploadFile()

        else:
            message = Message(catalog.i18nc("@info:status Don't translate the XML tags <filename> or <message>!",
                                            "Could not save to <filename>{0}</filename>: <message>{1}</message>").format(
                job.getFileName(), str(job.getError())), lifetime=0, title=catalog.i18nc("@info:title", "Warning"))
            message.show()
            self.writeError.emit(self)
        job.getStream().close()
