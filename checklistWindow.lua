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

--- Builds the internal checklist complexity structure.
--- Converts the provided checklist table into a keyed lookup.
---@param categories table|nil List of complexity category names
---@param checklists table|nil Checklist definition table
---@return table|nil Structured checklist table or nil if invalid
local function makeComplex(categories, checklists)
    if not (categories and checklists) then
        return nil
    end

    local newCategories = {}
    for key, value in pairs(checklists) do
        newCategories[key] = value
    end

    return newCategories
end

-- ------------------------------------------------------------
-- Constructor
-- ------------------------------------------------------------

--- Creates a new ChecklistWindow instance.
---@param name string Window title
---@param categories table|nil List of complexity levels (e.g. {"Sim", "Simple"})
---@param checklists table|nil Checklist definition table
---@return table ChecklistWindow instance
function ChecklistWindow:new(name, categories, checklists)
    local self = setmetatable({}, ChecklistWindow)

    self.visible = false
    self.checklists = {}

    self.checklistComplex   = makeComplex(categories, checklists)
    self.categories         = categories or nil
    self.complexity         = nil
    self.showMe             = false

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
    if self.checklistComplex then
        self.detailDropdown = ComboList.new()
        self.detailDropdown:setBounds(330, 10, 100, 20)
        self.detailDropdown:setVisible(true)
        self.detailDropdown:setSkin(dropdownSkin)
        self.ui:insertWidget(self.detailDropdown)

        for _, v in ipairs(self.categories) do
            self.detailDropdown:newItem(v)
        end

        -- Populate checklist dropdown and insert checklist widgets
        for key, group in pairs(self.checklistComplex) do
            self.headingDropdown:newItem(group.name)

            for _, checklist in pairs(group) do
                if type(checklist) ~= "string" then
                    local i = 0
                    for _, item in pairs(checklist.items) do
                        item.checkbox:setBounds(20, (20 * i) + 40, 400, 20)
                        item.checkbox:setVisible(false)
                        self.ui:insertWidget(item.checkbox)
                        i = i + 1
                    end
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

        for key, group in pairs(window.checklistComplex) do
            if group.name == selectedName then
                window:swapPage(key)
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
    -- ShowMe CheckBox
    -- --------------------------------------------------------
    self.showMeCheckBox = CheckBox.new("Show Me")
    self.showMeCheckBox:setBounds(440, 10, 100, 20)
    self.showMeCheckBox:setVisible(true)
    self.showMeCheckBox:setSkin(Skin.getSkin("checkBoxSkin_options"))
    self.ui:insertWidget(self.showMeCheckBox)

    -- Callback
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

    --- Called when the window is closed via the UI.
    --- Updates internal visibility state.
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
--- If a checklist key is provided, switches to that checklist.
--- Otherwise reloads the current checklist using the active complexity.
---@param checklistKey string|nil Checklist key to switch to
function ChecklistWindow:swapPage(checklistKey)
    -- Hide all checklists
    for _, group in pairs(self.checklistComplex) do
        for _, checklist in pairs(group) do
            if type(checklist) ~= "string" then
                checklist:setVisible(false)
            end
        end
    end

    -- Update current checklist if requested
    if checklistKey then
        self.currentChecklistKey   = checklistKey
        self.currentChecklistGroup = self.checklistComplex[checklistKey]
        self.headingDropdown:setText(self.currentChecklistGroup.name)
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
-- Simple checklist support (non-complex mode)
-- ------------------------------------------------------------

--- Adds a simple (non-complex) checklist to the window.
---@param checklist table Checklist instance
function ChecklistWindow:addChecklist(checklist)
    self.headingDropdown:newItem(checklist.name)

    local i = 0
    for _, item in pairs(checklist.items) do
        item.checkbox:setBounds(20, (20 * i) + 40, 400, 20)
        self.ui:insertWidget(item.checkbox)
        i = i + 1
    end

    table.insert(self.checklists, checklist)
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
