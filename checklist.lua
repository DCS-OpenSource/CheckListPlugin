--- Class for each individual checklist page

-- load dxgui
package.path = package.path..";"..LockOn_Options.script_path.."CheckListPlugin/?.lua"
require("dxguiLoader")

local Checklist = {}
Checklist.__index = Checklist

function Checklist:new(name)
    local self = setmetatable({}, Checklist)
    self.visible = false
    self.heading = ColorTextStatic.new(name or checklist)

    self.name = name or "Checklist"
    self.items = {}

    return self
end


--- Function to add items to checklist
--- @param name string Text to show on the checklist
--- @param clickable string|nil Clickable name for cockpit Hightlight
--- @param completionCallback function|nil Callback function to check if completed
--- @return nil nil Checklist Item is added to Checklist class items field (object.items)
function Checklist:addItem(name, clickable, completionCallback)
    local item = {}

    local checkbox = CheckBox.new(name)
    checkbox:setSkin(Skin.getSkin("checkBoxSkin_options"))

    item["name"] = name
    item["clickable"] = clickable
    item["callback"] = completionCallback
    item["checkbox"] = checkbox

    table.insert(self.items, item)
end

function Checklist:setVisible(visible)
    self.visible = visible
    self.heading:setVisible(self.visible)
    for _, item in pairs(self.items) do
        item.checkbox:setVisible(self.visible)
    end
end

function Checklist:addTable(list)
    for key, item in ipairs(list) do
        self:addItem(item[1], item[2], item[3])
    end
end

return Checklist
