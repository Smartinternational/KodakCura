# Copyright (c) 2017 3DPrinterOS
# Uranium is released under the terms of the LGPLv3 or higher.

from . import ThreeDPrinterOSOutputDevicePlugin

from UM.i18n import i18nCatalog
catalog = i18nCatalog("uranium")

def getMetaData():
    return {
    }

def register(app):
    return { "output_device": ThreeDPrinterOSOutputDevicePlugin.ThreeDPrinterOSOutputDevicePlugin() }
