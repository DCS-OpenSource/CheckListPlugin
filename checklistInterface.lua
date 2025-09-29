-- DXGUI search paths (keep if needed in aircraft env)
package.path = package.path..';./Scripts/?.lua;'
  ..'./Scripts/Common/?.lua;./Scripts/UI/?.lua;'
  ..'./Scripts/UI/F10View/?.lua;'
  ..'./Scripts/Speech/?.lua;'
  ..'./dxgui/bind/?.lua;./dxgui/loader/?.lua;./dxgui/skins/skinME/?.lua;./dxgui/skins/common/?.lua;'
  ..'./MissionEditor/modules/?.lua;'
  ..'./Scripts/Debug/?.lua;'
  ..'./Scripts/Input/?.lua;'

local DialogLoader = require('DialogLoader')
local Skin         = require('Skin')

local CheckListInterface = {}
CheckListInterface.__index = CheckListInterface

-- ---------- helpers ----------
local function bind_click(widget, fn)
  if not widget or type(fn) ~= 'function' then return end
  if widget.addChangeCallback then
    widget:addChangeCallback(function() fn(widget) end); return
  end
  if widget.addMouseUpCallback then
    widget:addMouseUpCallback(function() fn(widget) end); return
  end
  if widget.setOnChange then
    widget:setOnChange(function() fn(widget) end); return
  end
end

-- show one page, hide all others
local function loadPage(page, pages)
  for _, p in pairs(pages) do
    if p and p.setVisible then p:setVisible(false) end
  end
  if page and page.setVisible then page:setVisible(true) end
end

-- sanitize like the builder (strip spaces)
local function sanitizeId(s) return (tostring(s):gsub("%s+","")) end

-- find widget by name (supports both window and DialogLoader variants)
local function findWidget(root, name)
  if not root or not name then return nil end
  if root.findWidgetByName then return root:findWidgetByName(name) end
  if DialogLoader.findWidgetByName then return DialogLoader.findWidgetByName(root, name) end
  return nil
end

-- ---------- class ----------
function CheckListInterface:new(device, opts)
  local self = setmetatable({}, CheckListInterface)
  self.device   = device or (GetSelf and GetSelf() or nil)
  self.window   = nil
  self.buttons  = {}   -- id -> button widget
  self.pages    = {}   -- id -> panel widget
  self.activeId = nil

  -- optional: skins to swap when a tab is active/inactive
  self.skinActiveName   = (opts and opts.skinActiveName)   or 'buttonSkinGreenNew'
  self.skinInactiveName = (opts and opts.skinInactiveName) or 'buttonSkinGraybNew'
  return self
end

--- Register the .dlg file (creates the window) and optionally wire checklists.
--- @param dlgPath string
--- @param localization table|nil
--- @param names_or_opts table|nil  -- either { "Startup","Shutdown",... } or { names={...}, selectFirst=true|false }
function CheckListInterface:registerDialog(dlgPath, localization, names_or_opts)
  self.window = DialogLoader.spawnDialogFromFile(dlgPath, localization)
  if not self.window then
    print_message_to_user('CheckListPlugin: Failed to spawn dialog from '..tostring(dlgPath))
    return false
  end

  -- Optional auto-wire on register
  if names_or_opts then
    local names, selectFirst
    if names_or_opts.names then
      names       = names_or_opts.names
      selectFirst = (names_or_opts.selectFirst ~= false) -- default true
    else
      names       = names_or_opts
      selectFirst = true
    end
    self:wireChecklists(names, { selectFirst = selectFirst })
  end

  return true
end

--- Toggle the whole interface visibility
function CheckListInterface:setVisible(visible)
  if self.window and self.window.setVisible then
    self.window:setVisible(visible and true or false)
  end
end

-- swap button skins (optional visual feedback)
function CheckListInterface:_setButtonActive(btn, active)
  if not btn or not btn.setSkin then return end
  local skinName = active and self.skinActiveName or self.skinInactiveName
  local skin = Skin.getSkin(skinName)
  if skin then btn:setSkin(skin) end
end

-- change current page by id
function CheckListInterface:showChecklist(id)
  local page = self.pages[id]
  if not page then return end
  loadPage(page, self.pages)
  -- button visuals
  for pid, btn in pairs(self.buttons) do
    self:_setButtonActive(btn, pid == id)
  end
  self.activeId = id
end

--- Register a checklist "tab"
--- @param id     string unique id ("Startup", "Shutdown", etc.)
--- @param page   table (Panel) to show when active
--- @param button table (Button) that toggles this page
function CheckListInterface:addChecklist(id, page, button)
  if not id or not page or not button then
    print_message_to_user('addChecklist: missing id/page/button'); return
  end
  self.pages[id]   = page
  self.buttons[id] = button

  -- bind a closure (IMPORTANT: don't call loadPage here!)
  bind_click(button, function()
    self:showChecklist(id)
  end)
end

--- Wire checklists by names (matching the builder’s naming scheme).
--- Call after registerDialog(), or pass names into registerDialog(...).
--- @param names string[]  -- titles in the same order they were added to the builder
--- @param opts  table|nil -- { selectFirst=true|false }
function CheckListInterface:wireChecklists(names, opts)
  if not self.window then
    print_message_to_user('wireChecklists: dialog not registered'); return
  end
  if type(names) ~= 'table' then
    print_message_to_user('wireChecklists: names must be an array'); return
  end
  local selectFirst = (opts and opts.selectFirst ~= false)

  for i, title in ipairs(names) do
    local id     = sanitizeId(title)
    local btnKey = string.format("TopBtn_%02d_%s", i, id)
    local pnlKey = string.format("%sPanel", id)

    local btn = findWidget(self.window, btnKey)
    local pnl = findWidget(self.window, pnlKey)

    if not btn or not pnl then
      print_message_to_user(("Checklist wire: missing %s / %s"):format(btnKey, pnlKey))
    else
      self:addChecklist(id, pnl, btn)
    end
  end

  -- If nothing active yet and requested, select the first that was found
  if selectFirst and not self.activeId then
    for _, title in ipairs(names) do
      local id = sanitizeId(title)
      if self.pages[id] then
        self:showChecklist(id)
        break
      end
    end
  end
end

return CheckListInterface
