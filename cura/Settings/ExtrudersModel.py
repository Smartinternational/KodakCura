# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from typing import Iterable

from UM.i18n import i18nCatalog
import UM.Qt.ListModel
from UM.Application import Application
import UM.FlameProfiler

from cura.Settings.ExtruderStack import ExtruderStack  # To listen to changes on the extruders.

catalog = i18nCatalog("cura")

##  Model that holds extruders.
#
#   This model is designed for use by any list of extruders, but specifically
#   intended for drop-down lists of the current machine's extruders in place of
#   settings.
class ExtrudersModel(UM.Qt.ListModel.ListModel):
    # The ID of the container stack for the extruder.
    IdRole = Qt.UserRole + 1

    ##  Human-readable name of the extruder.
    NameRole = Qt.UserRole + 2
    ##  Is the extruder enabled?
    EnabledRole = Qt.UserRole + 9

    ##  Colour of the material loaded in the extruder.
    ColorRole = Qt.UserRole + 3

    ##  Index of the extruder, which is also the value of the setting itself.
    #
    #   An index of 0 indicates the first extruder, an index of 1 the second
    #   one, and so on. This is the value that will be saved in instance
    #   containers.
    IndexRole = Qt.UserRole + 4

    # The ID of the definition of the extruder.
    DefinitionRole = Qt.UserRole + 5

    # The material of the extruder.
    MaterialRole = Qt.UserRole + 6

    # The variant of the extruder.
    VariantRole = Qt.UserRole + 7
    StackRole = Qt.UserRole + 8

    ##  List of colours to display if there is no material or the material has no known
    #   colour.
    defaultColors = ["#ffc924", "#86ec21", "#22eeee", "#245bff", "#9124ff", "#ff24c8"]

    ##  Initialises the extruders model, defining the roles and listening for
    #   changes in the data.
    #
    #   \param parent Parent QtObject of this list.
    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.EnabledRole, "enabled")
        self.addRoleName(self.ColorRole, "color")
        self.addRoleName(self.IndexRole, "index")
        self.addRoleName(self.DefinitionRole, "definition")
        self.addRoleName(self.MaterialRole, "material")
        self.addRoleName(self.VariantRole, "variant")
        self.addRoleName(self.StackRole, "stack")

        self._update_extruder_timer = QTimer()
        self._update_extruder_timer.setInterval(100)
        self._update_extruder_timer.setSingleShot(True)
        self._update_extruder_timer.timeout.connect(self.__updateExtruders)

        self._simple_names = False

        self._active_machine_extruders = []  # type: Iterable[ExtruderStack]
        self._add_optional_extruder = False

        # Listen to changes
        Application.getInstance().globalContainerStackChanged.connect(self._extrudersChanged)  # When the machine is swapped we must update the active machine extruders
        Application.getInstance().getExtruderManager().extrudersChanged.connect(self._extrudersChanged)  # When the extruders change we must link to the stack-changed signal of the new extruder
        Application.getInstance().getContainerRegistry().containerMetaDataChanged.connect(self._onExtruderStackContainersChanged)  # When meta data from a material container changes we must update
        self._extrudersChanged()  # Also calls _updateExtruders

    addOptionalExtruderChanged = pyqtSignal()

    def setAddOptionalExtruder(self, add_optional_extruder):
        if add_optional_extruder != self._add_optional_extruder:
            self._add_optional_extruder = add_optional_extruder
            self.addOptionalExtruderChanged.emit()
            self._updateExtruders()

    @pyqtProperty(bool, fset = setAddOptionalExtruder, notify = addOptionalExtruderChanged)
    def addOptionalExtruder(self):
        return self._add_optional_extruder

    ##  Set the simpleNames property.
    def setSimpleNames(self, simple_names):
        if simple_names != self._simple_names:
            self._simple_names = simple_names
            self.simpleNamesChanged.emit()
            self._updateExtruders()

    ##  Emitted when the simpleNames property changes.
    simpleNamesChanged = pyqtSignal()

    ##  Whether or not the model should show all definitions regardless of visibility.
    @pyqtProperty(bool, fset = setSimpleNames, notify = simpleNamesChanged)
    def simpleNames(self):
        return self._simple_names

    ##  Links to the stack-changed signal of the new extruders when an extruder
    #   is swapped out or added in the current machine.
    #
    #   \param machine_id The machine for which the extruders changed. This is
    #   filled by the ExtruderManager.extrudersChanged signal when coming from
    #   that signal. Application.globalContainerStackChanged doesn't fill this
    #   signal; it's assumed to be the current printer in that case.
    def _extrudersChanged(self, machine_id = None):
        if machine_id is not None:
            if Application.getInstance().getGlobalContainerStack() is None:
                # No machine, don't need to update the current machine's extruders
                return
            if machine_id != Application.getInstance().getGlobalContainerStack().getId():
                # Not the current machine
                return

        # Unlink from old extruders
        for extruder in self._active_machine_extruders:
            extruder.containersChanged.disconnect(self._onExtruderStackContainersChanged)

        # Link to new extruders
        self._active_machine_extruders = []
        extruder_manager = Application.getInstance().getExtruderManager()
        for extruder in extruder_manager.getActiveExtruderStacks():
            if extruder is None: #This extruder wasn't loaded yet. This happens asynchronously while this model is constructed from QML.
                continue
            extruder.containersChanged.connect(self._onExtruderStackContainersChanged)
            self._active_machine_extruders.append(extruder)

        self._updateExtruders()  # Since the new extruders may have different properties, update our own model.

    def _onExtruderStackContainersChanged(self, container):
        # Update when there is an empty container or material change
        if container.getMetaDataEntry("type") == "material" or container.getMetaDataEntry("type") is None:
            # The ExtrudersModel needs to be updated when the material-name or -color changes, because the user identifies extruders by material-name
            self._updateExtruders()

    modelChanged = pyqtSignal()

    def _updateExtruders(self):
        self._update_extruder_timer.start()

    ##  Update the list of extruders.
    #
    #   This should be called whenever the list of extruders changes.
    @UM.FlameProfiler.profile
    def __updateExtruders(self):
        extruders_changed = False

        if self.rowCount() != 0:
            extruders_changed = True

        items = []

        global_container_stack = Application.getInstance().getGlobalContainerStack()
        if global_container_stack:

            # get machine extruder count for verification
            machine_extruder_count = global_container_stack.getProperty("machine_extruder_count", "value")

            for extruder in Application.getInstance().getExtruderManager().getActiveExtruderStacks():
                position = extruder.getMetaDataEntry("position", default = "0")  # Get the position
                try:
                    position = int(position)
                except ValueError:
                    # Not a proper int.
                    position = -1
                if position >= machine_extruder_count:
                    continue

                default_color = self.defaultColors[position] if 0 <= position < len(self.defaultColors) else self.defaultColors[0]
                color = extruder.material.getMetaDataEntry("color_code", default = default_color) if extruder.material else default_color
                
                if extruder.getMetaDataEntry("material_color"):
                    color = extruder.getMetaDataEntry("material_color")
                # construct an item with only the relevant information
                item = {
                    "id": extruder.getId(),
                    "name": extruder.getName(),
                    "enabled": extruder.isEnabled,
                    "color": color,
                    "index": position,
                    "definition": extruder.getBottom().getId(),
                    "material": extruder.material.getName() if extruder.material else "",
                    "variant": extruder.variant.getName() if extruder.variant else "",  # e.g. print core
                    "stack": extruder,
                }

                items.append(item)
                extruders_changed = True

        if extruders_changed:
            # sort by extruder index
            items.sort(key = lambda i: i["index"])

            # We need optional extruder to be last, so add it after we do sorting.
            # This way we can simply interpret the -1 of the index as the last item (which it now always is)
            if self._add_optional_extruder:
                item = {
                    "id": "",
                    "name": catalog.i18nc("@menuitem", "Not overridden"),
                    "enabled": True,
                    "color": "#ffffff",
                    "index": -1,
                    "definition": ""
                }
                items.append(item)

            self.setItems(items)
            self.modelChanged.emit()
