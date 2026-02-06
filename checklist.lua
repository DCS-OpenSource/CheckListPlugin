--- Class for each individual checklist page

-- load dxgui
package.path = package.path..";"..LockOn_Options.script_path.."CheckListPlugin/?.lua"
require("dxguiLoader")

------------------------------------------------------------
-- Highlight ID management
------------------------------------------------------------

-- Global increasing highlight index
local NEXT_HIGHLIGHT_INDEX = 1


------------------------------------------------------------
-- Clickable helpers
------------------------------------------------------------

-- Normalize clickable descriptor into a flat list
local function resolveClickables(clickable)
    if not clickable then return {} end

    if type(clickable) == "string" then
        return { { switch = clickable, size = 0.05 } }
    end

    if clickable.switch or clickable.position then
        return { clickable }
    end

    if clickable.group then
        return clickable.group
    end

    return {}
end


local function highlightItem(item, showMe)
    if not showMe then return end
    if not item.clickable then return end

    item.highlightIndices = {}

    local list = resolveClickables(item.clickable)

    for _, c in ipairs(list) do
        local id = NEXT_HIGHLIGHT_INDEX
        NEXT_HIGHLIGHT_INDEX = NEXT_HIGHLIGHT_INDEX + 1

        -- Switch-based highlight
        if c.switch then
            a_cockpit_highlight(id, c.switch, c.size or 0.05, "")

        -- Position-based highlight
        elseif c.position then
            local size = c.size or 0.05
            a_cockpit_highlight_position(id, c.position[1], c.position[2], c.position[3], size, size, size)
        end

        table.insert(item.highlightIndices, id)
    end
end


-- Remove exactly the highlights that were added for this item
local function removeItemHighlights(item)
    if not item or not item.highlightIndices then
        return
    end

    for _, id in ipairs(item.highlightIndices) do
        a_cockpit_remove_highlight(id)
    end

    item.highlightIndices = nil
end


------------------------------------------------------------
-- Checklist class
------------------------------------------------------------

local Checklist = {}
Checklist.__index = Checklist

function Checklist:new(name)
    local self = setmetatable({}, Checklist)

    self.visible = false
    self.heading = ColorTextStatic.new(name or "Checklist")
    self.index   = 1
    self.name    = name or "Checklist"
    self.items   = {}
    self.showMe  = false

    return self
end


------------------------------------------------------------
-- Internal step control
------------------------------------------------------------

local function advanceStep(checklist)
    local current = checklist.items[checklist.index]
    if current then
        removeItemHighlights(current)
    end

    checklist.index = checklist.index + 1

    local nextItem = checklist.items[checklist.index]
    if nextItem then
        highlightItem(nextItem, checklist.showMe)
    end
end


local function revertStep(checklist)
    local current = checklist.items[checklist.index]
    if current then
        removeItemHighlights(current)
    end

    checklist.index = checklist.index - 1

    local prev = checklist.items[checklist.index]
    if prev then
        highlightItem(prev, checklist.showMe)
    end
end


------------------------------------------------------------
-- Public API
------------------------------------------------------------

--- Add an item to the checklist
--- @param name string Text to show on the checklist
--- @param clickable string|table|nil Clickable descriptor or group
--- @param completionCallback function|nil Callback to check completion
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
    item.highlightIndices = nil

    local checklist = self

    function checkbox:onChange()
        if item.checkbox:getState() == true then
            -- CHECK
            if item.index == checklist.index then
                advanceStep(checklist)
            end
        else
            -- UNCHECK
            if item.index == checklist.index - 1 then
                revertStep(checklist)
            end
        end
    end

    table.insert(self.items, item)
end


function Checklist:setShowMe(enabled)
    self.showMe = enabled

    -- Clear all highlights first
    for _, item in ipairs(self.items) do
        removeItemHighlights(item)
    end

    -- Restore current step if enabled
    if enabled then
        local item = self.items[self.index]
        if item then
            highlightItem(item, true)
        end
    end
end


function Checklist:setVisible(visible)
    self.visible = visible
    self.heading:setVisible(self.visible)

    for _, item in ipairs(self.items) do
        item.checkbox:setVisible(self.visible)
    end
end


function Checklist:addTable(list)
    for _, item in ipairs(list) do
        self:addItem(item[1], item[2], item[3])
    end
end


return Checklist
