--- Class for each individual checklist page

-- load dxgui
package.path = package.path..";"..LockOn_Options.script_path.."CheckListPlugin/?.lua"
require("dxguiLoader")


local function incrementClickable(index, clickable, showMe)
    if not showMe then return end
    a_cockpit_remove_highlight(index - 1)
    a_cockpit_highlight(index, clickable, 0.05, "")
end

local function decrementClickable(index, clickable, showMe)
    if not showMe then return end
    a_cockpit_remove_highlight(index + 1)
    a_cockpit_highlight(index, clickable, 0.05, "")
end


local Checklist = {}
Checklist.__index = Checklist

function Checklist:new(name)
    local self = setmetatable({}, Checklist)
    self.visible = false
    self.heading = ColorTextStatic.new(name or checklist)
    self.index = 1

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

    local index = #self.items + 1

    item.name      = name
    item.clickable = clickable
    item.callback  = completionCallback
    item.checkbox  = checkbox
    item.index     = index

    local checklist = self

    function checkbox:onChange()
        if item.checkbox:getState() == true then -- CHECK
            if item.index == checklist.index then
                checklist.index = checklist.index + 1
                if checklist.index <= #checklist.items then
                    incrementClickable(checklist.index, checklist.items[checklist.index].clickable, checklist.showMe)
                else
                    a_cockpit_remove_highlight(#checklist.items) -- checklist complete
                end
            end
        else -- UNCHECK
            if item.index == checklist.index - 1 then -- undo last completed item
                checklist.index = checklist.index - 1 -- step back
                decrementClickable(checklist.index, checklist.items[checklist.index].clickable, checklist.showMe)
            end
        end
    end
    table.insert(self.items, item)
end


function Checklist:setShowMe(enabled)
    self.showMe = enabled
    if not enabled then
        for _, item in ipairs(self.items) do
            a_cockpit_remove_highlight(item.index)
        end
    else
        if self.index <= #self.items then
            local item = self.items[self.index]
            if item and item.clickable then
                a_cockpit_highlight(self.index, item.clickable, 0.05, "")
            end
        end
    end
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
