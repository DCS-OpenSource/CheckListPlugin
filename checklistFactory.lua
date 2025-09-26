-- This is needed to make DXGUI work in the aircraft Lua environment
package.path = package.path..';./Scripts/?.lua;'
    ..'./Scripts/Common/?.lua;./Scripts/UI/?.lua;'
    .. './Scripts/UI/F10View/?.lua;'
    .. './Scripts/Speech/?.lua;'
    .. './dxgui/bind/?.lua;./dxgui/loader/?.lua;./dxgui/skins/skinME/?.lua;./dxgui/skins/common/?.lua;'
    .. './MissionEditor/modules/?.lua;'
    .. './Scripts/Debug/?.lua;'
    .. './Scripts/Input/?.lua;'

local DialogLoader = require('DialogLoader')

local CheckListFactory = {}
CheckListFactory.__index = CheckListFactory


function CheckListFactory:new(device)
    local self = setmetatable({}, CheckListFactory)
    self.device = device or GetSelf()
    self.window = nil
    return self
end


--- Function to add the .dlg file to the CheckListPlugin
--- @param dlgPath string string path to custom dlg file
--- @param localization table|nil
--- @return nil
function CheckListFactory:registerDialog(dlgPath, localization)
    -- Create a NEW window from file:
    self.window = DialogLoader.spawnDialogFromFile(dlgPath, localization)
    if not self.window then
      print_message_to_user('CheckListPlugin: Failed to spawn dialog from ' .. dlgPath)
      return
    end
end


--- Function to toggle the visibility of the checklists
--- @param visible boolean visible true/false
--- @return nil
function CheckListFactory:setVisible(visible)
    if self.window then self.window:setVisible(visible) end
end






return CheckListFactory
