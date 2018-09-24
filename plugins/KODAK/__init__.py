# Copyright (c) 2017 3DPrinterOS
# Uranium is released under the terms of the LGPLv3 or higher.

from . import KodakOutputDevicePlugin

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "view": {
            "name": catalog.i18nc("@item:inlistbox", "KODAK Integration"),
            "weight": 1
        }
    }

def register(app):
    return { "output_device": KodakOutputDevicePlugin.KodakOutputDevicePlugin() }
