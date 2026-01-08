--- Parent Class for the Checklist window.

-- load dxgui
package.path = package.path..";"..LockOn_Options.script_path.."CheckListPlugin/?.lua"

require("dxguiLoader")

local ChecklistWindow = {}
ChecklistWindow.__index = ChecklistWindow


function ChecklistWindow:new(name)
    local self = setmetatable({}, ChecklistWindow)

    self.visible = false
    self.checklists = {}
    self.ui = Window.new(100, 100, 500, 500, name)

    self.ui.onClose = function() self.visible = false end -- set visible state if checklist is closed with x instead of keybind

    self.ui:setVisible(self.visible)

    return self
end


--- Function to change current checklist
--- @param newChecklist table Checklist item to swap to.
function ChecklistWindow:swapPage(newChecklist)
    for _, list in pairs(self.checklists) do
        list:setVisible(false)
    end
    newChecklist:setVisible(true)
end


--- Function to add checklist to window
--- @param checklist table checklist object.
function ChecklistWindow:addChecklist(checklist)
    checklist.heading:setBounds((20), (10), 400, 15)
    self.ui:insertWidget(checklist.heading)
    local i = 0
    for _, item in pairs(checklist.items) do
        item.checkbox:setBounds((20), (20 * i) + 30, 400, 15)
        self.ui:insertWidget(item.checkbox)
        i = i + 1
    end
    table.insert(self.checklists, checklist)
end


--- Show/Hide the checklist window
--- @param visible boolean show window true/false
function ChecklistWindow:showChecklist(visible)
    self.visible = visible
    self.ui:setVisible(self.visible)
end


--- Toggle Checklist Window Visibility
function ChecklistWindow:toggleChecklist()
    self.visible = not self.visible
    self.ui:setVisible(self.visible)
end


--- Function to cleanup ui window on quit to prevent rare edgecase DCS Crash
function ChecklistWindow:kill()
    self.ui:kill()
end


return ChecklistWindow