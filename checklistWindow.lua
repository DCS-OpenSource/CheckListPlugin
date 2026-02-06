--- Parent class for the Checklist window.
--- Handles UI creation, checklist page swapping, and complexity selection.

-- load dxgui
package.path = package.path..";"..LockOn_Options.script_path.."CheckListPlugin/?.lua"
require("dxguiLoader")

local windowSkin   = require("skins.CheckListWindowSkin1")
local dropdownSkin = require("skins.DropdownSKin1")

local ChecklistWindow = {}
ChecklistWindow.__index = ChecklistWindow

-- ------------------------------------------------------------
-- Internal helpers
-- ------------------------------------------------------------

--- Finds a checklist group by its id.
---@param checklists table Ordered checklist group list
---@param id string Checklist id
---@return table|nil Checklist group or nil if not found
local function findChecklistById(checklists, id)
    for _, group in ipairs(checklists) do
        if group.id == id then
            return group
        end
    end
    return nil
end


--- Hides all checklist pages.
---@param checklists table Ordered checklist group list
local function hideAllChecklists(checklists)
    for _, group in ipairs(checklists) do
        for _, checklist in pairs(group) do
            if type(checklist) ~= "string" and checklist.setVisible then
                checklist:setVisible(false)
            end
        end
    end
end

-- ------------------------------------------------------------
-- Constructor
-- ------------------------------------------------------------

--- Creates a new ChecklistWindow instance.
---@param name string Window title
---@param categories table|nil List of complexity levels (e.g. {"Sim", "Simple"})
---@param checklists table|nil Ordered checklist definition list
---@return table ChecklistWindow instance
function ChecklistWindow:new(name, categories, checklists)
    local self = setmetatable({}, ChecklistWindow)

    self.visible    = false
    self.checklists = checklists or {}   -- ordered array of checklist groups
    self.categories = categories or {}
    self.complexity = nil
    self.showMe     = false

    -- Current state
    self.currentChecklistKey   = nil
    self.currentChecklistGroup = nil

    -- --------------------------------------------------------
    -- Window
    -- --------------------------------------------------------
    self.ui = Window.new(100, 100, 540, 500, name)
    self.ui:setSkin(windowSkin)

    -- --------------------------------------------------------
    -- Checklist selector dropdown
    -- --------------------------------------------------------
    self.headingDropdown = ComboList.new()
    self.headingDropdown:setBounds(20, 10, 300, 20)
    self.headingDropdown:setVisible(true)
    self.headingDropdown:setSkin(dropdownSkin)
    self.ui:insertWidget(self.headingDropdown)

    -- --------------------------------------------------------
    -- Complexity selector dropdown
    -- --------------------------------------------------------
    self.detailDropdown = ComboList.new()
    self.detailDropdown:setBounds(330, 10, 100, 20)
    self.detailDropdown:setVisible(true)
    self.detailDropdown:setSkin(dropdownSkin)
    self.ui:insertWidget(self.detailDropdown)

    for _, category in ipairs(self.categories) do
        self.detailDropdown:newItem(category)
    end

    -- --------------------------------------------------------
    -- Populate checklist dropdown and insert checklist widgets
    -- --------------------------------------------------------
    for _, group in ipairs(self.checklists) do
        self.headingDropdown:newItem(group.name)

        for _, checklist in pairs(group) do
            if type(checklist) ~= "string" and checklist.items then
                local i = 0
                for _, item in ipairs(checklist.items) do
                    item.checkbox:setBounds(20, (20 * i) + 40, 400, 20)
                    item.checkbox:setVisible(false)
                    self.ui:insertWidget(item.checkbox)
                    i = i + 1
                end
            end
        end
    end

    local window = self

    -- --------------------------------------------------------
    -- Checklist dropdown callback
    -- --------------------------------------------------------
    function self.headingDropdown:onChange(item)
        if not item then return end

        local selectedName = item:getText()
        for _, group in ipairs(window.checklists) do
            if group.name == selectedName then
                window:swapPage(group.id)
                return
            end
        end
    end

    -- --------------------------------------------------------
    -- Complexity dropdown callback
    -- --------------------------------------------------------
    function self.detailDropdown:onChange(item)
        if not item then return end
        window.complexity = item:getText()
        window:swapPage()
    end

    -- --------------------------------------------------------
    -- Show Me checkbox
    -- --------------------------------------------------------
    self.showMeCheckBox = CheckBox.new("Show Me")
    self.showMeCheckBox:setBounds(440, 10, 100, 20)
    self.showMeCheckBox:setVisible(true)
    self.showMeCheckBox:setSkin(Skin.getSkin("checkBoxSkin_options"))
    self.ui:insertWidget(self.showMeCheckBox)

    function self.showMeCheckBox:onChange()
        window.showMe = window.showMeCheckBox:getState()
        if window.currentChecklistGroup and window.complexity then
            local checklist = window.currentChecklistGroup[window.complexity]
            if checklist then
                checklist:setShowMe(window.showMe)
            end
        end
    end

    -- --------------------------------------------------------
    -- Window close handler
    -- --------------------------------------------------------
    self.ui.onClose = function()
        self.visible = false
    end

    self.ui:setVisible(self.visible)
    return self
end

-- ------------------------------------------------------------
-- Page management
-- ------------------------------------------------------------

--- Swaps the currently visible checklist page.
--- If a checklist id is provided, switches to that checklist.
--- Otherwise reloads the current checklist using the active complexity.
---@param checklistKey string|nil Checklist id to switch to
function ChecklistWindow:swapPage(checklistKey)
    hideAllChecklists(self.checklists)

    if checklistKey then
        self.currentChecklistKey   = checklistKey
        self.currentChecklistGroup = findChecklistById(self.checklists, checklistKey)
        if self.currentChecklistGroup then
            self.headingDropdown:setText(self.currentChecklistGroup.name)
        end
    end

    if not self.currentChecklistGroup or not self.complexity then
        return
    end

    local checklist = self.currentChecklistGroup[self.complexity]
    if checklist then
        checklist:setVisible(true)
    end
end

-- ------------------------------------------------------------
-- Complexity management
-- ------------------------------------------------------------

--- Sets the active checklist complexity.
---@param complexity string Complexity key (e.g. "Sim", "Simple")
function ChecklistWindow:swapComplexity(complexity)
    self.complexity = complexity
    self.detailDropdown:setText(self.complexity)
end

-- ------------------------------------------------------------
-- Visibility control
-- ------------------------------------------------------------

--- Sets checklist window visibility.
---@param visible boolean True to show, false to hide
function ChecklistWindow:showChecklist(visible)
    self.visible = visible
    self.ui:setVisible(self.visible)
end

--- Toggles checklist window visibility.
function ChecklistWindow:toggleChecklist()
    self.visible = not self.visible
    self.ui:setVisible(self.visible)
end

-- ------------------------------------------------------------
-- Cleanup
-- ------------------------------------------------------------

--- Destroys the checklist window and all associated widgets.
--- Should be called on device shutdown.
function ChecklistWindow:kill()
    self.ui:kill()
end

return ChecklistWindow
