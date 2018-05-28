# Copyright (c) 2016 Ultimaker B.V.
# Uranium is released under the terms of the LGPLv3 or higher.

from UM.Preferences import Preferences
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from .ThreeDPrinterOSOutputDevice import ThreeDPrinterOSOutputDevice

from UM.i18n import i18nCatalog
catalog = i18nCatalog("uranium")


##  Implements an OutputDevicePlugin that provides a single instance of ThreeDPrinterOSOutputDevice
class ThreeDPrinterOSOutputDevicePlugin(OutputDevicePlugin):
    def __init__(self):
        super().__init__()

        Preferences.getInstance().addPreference("3dprinteros/last_used_type", "")
        Preferences.getInstance().addPreference("3dprinteros/dialog_save_path", "")

    def start(self):
        self.getOutputDeviceManager().addOutputDevice(ThreeDPrinterOSOutputDevice(self.getPluginId()))

    def stop(self):
        self.getOutputDeviceManager().removeOutputDevice("3dprinteros")