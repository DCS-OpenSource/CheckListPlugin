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

    -- Heading/dropdown for checklist swapping
    self.headingDropdown = ComboList.new()
    self.headingDropdown:setBounds(20, 10, 400, 15)
    self.headingDropdown:setVisible(true)
    self.ui:insertWidget(self.headingDropdown)

    local window = self -- need reference for inside dropdown class, see below

    -- Configure heading box callback
    function self.headingDropdown:onChange(item)
        if not item then return end

        local name = item:getText()

        for _, checklist in pairs(window.checklists) do
            if checklist.name == name then
                window:swapPage(checklist) -- self doesn't work here
                break
            end
        end
    end

    self.ui.onClose = function() self.visible = false end -- update the state of visibile if user manually closes window

    self.ui:setVisible(self.visible)

    return self
end


--- Function to change current checklist
--- @param newChecklist table Checklist item to swap to.
function ChecklistWindow:swapPage(newChecklist)
    self.headingDropdown:setText(newChecklist.name)
    for _, list in pairs(self.checklists) do
        list:setVisible(false)
    end
    newChecklist:setVisible(true)
end


--- Function to add checklist to window
--- @param checklist table checklist object.
function ChecklistWindow:addChecklist(checklist)
    self.headingDropdown:newItem(checklist.name) -- Add Checklist to dropdown

    local i = 0
    for _, item in pairs(checklist.items) do
        item.checkbox:setBounds(20, (20 * i) + 30, 400, 15)
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