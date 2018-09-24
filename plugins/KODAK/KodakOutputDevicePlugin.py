# Copyright (c) 2016 Ultimaker B.V.
# Uranium is released under the terms of the LGPLv3 or higher.

from UM.Preferences import Preferences
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from .KodakOutputDevice import KodakOutputDevice

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")


##  Implements an OutputDevicePlugin that provides a single instance of ThreeDPrinterOSOutputDevice
class KodakOutputDevicePlugin(OutputDevicePlugin):
    def __init__(self):
        super().__init__()

        Preferences.getInstance().addPreference("kodak/last_used_type", "")
        Preferences.getInstance().addPreference("kodak/dialog_save_path", "")

    def start(self):
        self.getOutputDeviceManager().addOutputDevice(KodakOutputDevice(self.getPluginId()))

    def stop(self):
        self.getOutputDeviceManager().removeOutputDevice("kodak")