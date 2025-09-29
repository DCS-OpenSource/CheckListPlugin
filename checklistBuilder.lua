------------------------------------------------------------
-- DialogChecklistBuilder.lua
-- Build DXGUI .dlg tables for DCS “checklist” style windows
------------------------------------------------------------

local lfs = require("lfs")

local DialogChecklistBuilder = {}
DialogChecklistBuilder.__index = DialogChecklistBuilder

------------------------------------------------------------
-- Default layout constants
------------------------------------------------------------
local DEFAULTS = {
  rebuild = true,
  windowX = 200, windowY = 150, windowW = 640, windowH = 420,
  contentTopY = 15 + (20 * 1.2) + 10, -- row2 + 10 with row1=margin=15, rowSpacing=buttonHeight*1.2
  contentHeight = 380,

  buttonHeight = 20,
  buttonWidth = 75,
  margin = 15,
  columnSpacingDelta = 5, -- columnSpacing = buttonWidth + 5

  rowSpacing = 20 * 1.2,  -- buttonHeight * 1.2
  row1 = 15,
  -- Check item verticals (inside content panels)
  itemStartY = 40,
  itemStepY  = 25,

  zOrder = 120,
  title = "Caffeine Simulations - Checklists",

  -- skin names
  skin = {
    window = "windowSkin",
    panel  = "panelSkin",
    staticCaption = "staticOptionsCaptionSkin",
    checkbox = "checkBoxSkin_options",
    topBtnActive  = "buttonSkinGreenNew",
    topBtnInactive= "buttonSkinGraybNew",
    redBtnCarrier = "buttonSkinRedNew",
  },

  -- coloring for the window body
  windowReleasedBkg = "0xCC202020",
  headerTextColor   = "0xffffffaa",
  headerCenter      = "0x00000066",
}

------------------------------------------------------------
-- Helper: compute columns for top buttons based on count
------------------------------------------------------------
local function computeTopButtonPositions(cfg, count)
  local columns = {}
  local columnSpacing = cfg.buttonWidth + cfg.columnSpacingDelta
  local c = cfg.margin
  for i=1,count do
    columns[i] = c
    c = c + columnSpacing
  end
  return columns
end

------------------------------------------------------------
-- Helper: shallow clone a table
------------------------------------------------------------
local function tclone(t)
  local r = {}
  for k,v in pairs(t) do r[k]=v end
  return r
end

------------------------------------------------------------
-- Helper: Lua table serializer -> returns a string
-- Produces `dialog = { ... }`
------------------------------------------------------------
local function serialize(val, indent)
  indent = indent or ""
  local t = type(val)
  if t == "string" then
    -- keep quotes; escape backslashes and quotes
    local s = val:gsub("\\","\\\\"):gsub("\n","\\n"):gsub("\"","\\\"")
    return "\"" .. s .. "\""
  elseif t == "number" or t == "boolean" or t == "nil" then
    return tostring(val)
  elseif t == "table" then
    local isArray = true
    local maxIndex = 0
    for k,_ in pairs(val) do
      if type(k) ~= "number" then isArray=false break end
      if k > maxIndex then maxIndex = k end
    end

    local pieces = {}
    table.insert(pieces, "{")
    local nextIndent = indent .. "    "

    if isArray then
      for i=1,maxIndex do
        local v = val[i]
        table.insert(pieces, "\n"..nextIndent..serialize(v, nextIndent)..",")
      end
    else
      -- stable-ish ordering: keys sorted alpha, numbers first
      local keys = {}
      for k,_ in pairs(val) do table.insert(keys, k) end
      table.sort(keys, function(a,b)
        if type(a)==type(b) then return tostring(a) < tostring(b) end
        return type(a) < type(b)
      end)
      for _,k in ipairs(keys) do
        local v = val[k]
        local keyStr
        if type(k)=="string" and k:match("^[_%a][_%w]*$") then
          keyStr = "[\""..k.."\"]"
        else
          keyStr = "["..serialize(k,nextIndent).."]"
        end
        table.insert(pieces, "\n"..nextIndent..keyStr.." = "..serialize(v, nextIndent)..",")
      end
    end

    table.insert(pieces, "\n"..indent.."}")
    return table.concat(pieces)
  else
    return "\"<unsupported:"..t..">\""
  end
end

------------------------------------------------------------
-- Create builder
------------------------------------------------------------
function DialogChecklistBuilder:new(opts)
  local cfg = tclone(DEFAULTS)
  if opts then
    for k,v in pairs(opts) do
      if type(v)=="table" and type(cfg[k])=="table" then
        for kk,vv in pairs(v) do cfg[k][kk]=vv end
      else
        cfg[k]=v
      end
    end
  end

  local o = {
    cfg = cfg,
    checklists = {},         -- { { name=..., items={...} }, ... }
    _current = nil,
  }
  return setmetatable(o, self)
end

------------------------------------------------------------
-- Start a new checklist page
-- opts: { active = boolean } (optional)
------------------------------------------------------------
function DialogChecklistBuilder:addChecklist(name, opts)
  assert(name and name~="", "Checklist name is required")
  local entry = { name = name, items = {}, active = opts and opts.active or false }
  table.insert(self.checklists, entry)
  self._current = entry
  return self
end

------------------------------------------------------------
-- Add an item (checkbox row) to the current checklist
------------------------------------------------------------
function DialogChecklistBuilder:addItem(text)
  assert(self._current, "addItem() called before addChecklist()")
  table.insert(self._current.items, { text = tostring(text or "") })
  return self
end

------------------------------------------------------------
-- Internal: build the window/skin scaffolding matching your sample
------------------------------------------------------------
function DialogChecklistBuilder:_buildWindowSkin()
  local cfg = self.cfg
  return {
    ["params"] = { ["name"] = cfg.skin.window },
    ["skins"] = {
      ["header"] = {
        ["skinData"] = {
          ["params"] = {
            ["hasCloseButton"] = false,
            ["insets"] = { ["left"]=2, ["top"]=2, ["right"]=2, ["bottom"]=2 }
          },
          ["states"] = {
            ["released"] = {
              [1] = {
                ["bkg"]  = { ["center_center"] = cfg.headerCenter },
                ["text"] = { ["color"] = cfg.headerTextColor }
              }
            }
          }
        }
      }
    },
    ["states"] = {
      ["released"] = {
        [1] = { ["bkg"] = { ["center_center"] = cfg.windowReleasedBkg } }
      }
    }
  }
end

------------------------------------------------------------
-- Internal: top button node
------------------------------------------------------------
function DialogChecklistBuilder:_makeTopButton(name, x, active)
  local cfg = self.cfg
  return {
    ["type"] = "Button",
    ["params"] = {
      ["bounds"]  = { ["x"] = x, ["y"] = cfg.row1, ["w"] = cfg.buttonWidth, ["h"] = cfg.buttonHeight },
      ["enabled"] = true, ["visible"] = true, ["text"] = name, ["zindex"] = 5
    },
    ["skin"] = { ["params"] = { ["name"] = active and cfg.skin.topBtnActive or cfg.skin.topBtnInactive } }
  }
end

------------------------------------------------------------
-- Internal: content panel (per checklist page)
------------------------------------------------------------
function DialogChecklistBuilder:_makeChecklistPanel(page, visible)
  local cfg = self.cfg
  local children = {}

  -- Title
  children["Title"] = {
    ["type"] = "Static",
    ["params"] = {
      ["bounds"] = { ["x"] = 24, ["y"] = 10, ["w"] = 260, ["h"] = 20 },
      ["text"] = string.upper(page.name),
      ["enabled"] = true, ["visible"] = true
    },
    ["skin"] = { ["params"] = { ["name"] = cfg.skin.staticCaption } }
  }

  -- Items (checkboxes)
  local y = cfg.itemStartY
  for idx, item in ipairs(page.items) do
    local key = string.format("Item_%02d", idx)
    children[key] = {
      ["type"] = "CheckBox",
      ["params"] = {
        ["bounds"] = { ["x"] = 24, ["y"] = y, ["w"] = 260, ["h"] = 18 },
        ["text"] = item.text, ["state"] = false, ["enabled"] = true, ["visible"] = true
      },
      ["skin"] = { ["params"] = { ["name"] = cfg.skin.checkbox } }
    }
    y = y + cfg.itemStepY
  end

  return {
    ["type"] = "Panel",
    ["params"] = {
      ["bounds"]  = { ["x"] = 0, ["y"] = 0, ["w"] = cfg.windowW, ["h"] = cfg.contentHeight },
      ["enabled"] = true, ["visible"] = visible, ["zindex"] = 1
    },
    ["skin"] = { ["params"] = { ["name"] = cfg.skin.panel } },
    ["children"] = children
  }
end

------------------------------------------------------------
-- Internal: hidden “red skin carrier”, preserved from your sample
------------------------------------------------------------
function DialogChecklistBuilder:_makeRedSkinCarrier()
  return {
    ["type"] = "Button",
    ["params"] = {
      ["bounds"]  = { ["x"] = 50, ["y"] = 10, ["w"] = 150, ["h"] = 30 },
      ["enabled"] = true, ["visible"] = false, ["text"] = "RED", ["zindex"] = 0
    },
    ["skin"] = {
      ["params"] = {
        ["name"] = self.cfg.skin.redBtnCarrier,
        ["textWrapping"] = false,
        ["useEllipsis"]  = false,
      },
      ["states"] = {
        -- Using explicit images/rects/insets as in your provided block
        ["disabled"] = {
          [1] = {
            ["bkg"] = {
              ["file"] = "dxgui\\skins\\skinme\\images\\buttons\\buttons(new)\\released\\btnred.png",
              ["rect"] = { ["x1"]=10, ["y1"]=10, ["x2"]=130, ["y2"]=40 },
              ["insets"] = { ["left"]=4, ["top"]=4, ["right"]=4, ["bottom"]=4 },
              ["left_top"]="0xff0000ff",["left_center"]="0xff0000ff",["left_bottom"]="0xff0000ff",
              ["center_top"]="0xff0000ff",["center_center"]="0xff0000ff",["center_bottom"]="0xff0000ff",
              ["right_top"]="0xff0000ff",["right_center"]="0xff0000ff",["right_bottom"]="0xff0000ff",
            },
            ["text"] = { ["fontSize"] = 11 }
          }
        },
        ["hover"] = {
          [1] = {
            ["bkg"] = {
              ["file"] = "dxgui\\skins\\skinme\\images\\buttons\\buttons(new)\\hover\\btnred.png",
              ["rect"] = { ["x1"]=10, ["y1"]=10, ["x2"]=130, ["y2"]=40 },
              ["insets"] = { ["left"]=4, ["top"]=4, ["right"]=4, ["bottom"]=4 },
              ["left_top"]="0xff0000ff",["left_center"]="0xff0000ff",["left_bottom"]="0xff0000ff",
              ["center_top"]="0xff0000ff",["center_center"]="0xff0000ff",["center_bottom"]="0xff0000ff",
              ["right_top"]="0xff0000ff",["right_center"]="0xff0000ff",["right_bottom"]="0xff0000ff",
            },
            ["text"] = { ["fontSize"] = 11 }
          }
        },
        ["pressed"] = {
          [1] = {
            ["bkg"] = {
              ["file"] = "dxgui\\skins\\skinme\\images\\buttons\\buttons(new)\\pressed\\btnred.png",
              ["rect"] = { ["x1"]=10, ["y1"]=10, ["x2"]=130, ["y2"]=40 },
              ["insets"] = { ["left"]=4, ["top"]=4, ["right"]=4, ["bottom"]=4 },
              ["left_top"]="0xff0000ff",["left_center"]="0xff0000ff",["left_bottom"]="0xff0000ff",
              ["center_top"]="0xff0000ff",["center_center"]="0xff0000ff",["center_bottom"]="0xff0000ff",
              ["right_top"]="0xff0000ff",["right_center"]="0xff0000ff",["right_bottom"]="0xff0000ff",
            },
            ["text"] = { ["fontSize"] = 11 }
          }
        },
        ["released"] = {
          [1] = {
            ["bkg"] = {
              ["file"] = "dxgui\\skins\\skinme\\images\\buttons\\buttons(new)\\released\\btnred.png",
              ["rect"] = { ["x1"]=10, ["y1"]=10, ["x2"]=130, ["y2"]=40 },
              ["insets"] = { ["left"]=4, ["top"]=4, ["right"]=4, ["bottom"]=4 },
              ["left_top"]="0xff0000ff",["left_center"]="0xff0000ff",["left_bottom"]="0xff0000ff",
              ["center_top"]="0xff0000ff",["center_center"]="0xff0000ff",["center_bottom"]="0xff0000ff",
              ["right_top"]="0xff0000ff",["right_center"]="0xff0000ff",["right_bottom"]="0xff0000ff",
            },
            ["text"] = { ["fontSize"] = 11 }
          }
        }
      }
    }
  }
end

------------------------------------------------------------
-- Build the .dlg string (dialog = { ... })
------------------------------------------------------------
function DialogChecklistBuilder:build()
  assert(#self.checklists > 0, "No checklists added")

  -- ensure exactly one active (default to first)
  local anyActive = false
  for _,c in ipairs(self.checklists) do if c.active then anyActive = true break end end
  if not anyActive then self.checklists[1].active = true end

  local cfg = self.cfg
  local topBtnXs = computeTopButtonPositions(cfg, #self.checklists)

  -- Children: Top buttons + ContentPanel (+ RedButtonSkinCarrier)
  local children = {}

  -- Red skin carrier (hidden) – preserved as in your file
  children["RedButtonSkinCarrier"] = self:_makeRedSkinCarrier()

  -- Top buttons
  for i, page in ipairs(self.checklists) do
    local btnKey = string.format("TopBtn_%02d_%s", i, page.name:gsub("%s+",""))
    children[btnKey] = self:_makeTopButton(page.name, topBtnXs[i], page.active)
  end

  -- Content panel: contains one sub-panel per checklist
  local contentChildren = {}
  for i, page in ipairs(self.checklists) do
    local pKey = string.format("%sPanel", page.name:gsub("%s+",""))
    contentChildren[pKey] = self:_makeChecklistPanel(page, page.active)
  end

  children["ContentPanel"] = {
    ["type"] = "Panel",
    ["params"] = {
      ["bounds"]  = { ["x"] = 0, ["y"] = cfg.contentTopY, ["w"] = cfg.windowW, ["h"] = cfg.contentHeight },
      ["enabled"] = true, ["visible"] = true, ["zindex"] = 1,
    },
    ["skin"] = { ["params"] = { ["name"] = cfg.skin.panel } },
    ["children"] = contentChildren
  }

  -- Root window
  local root = {
    ["type"] = "Window",
    ["params"] = {
      ["bounds"] = { ["x"] = cfg.windowX, ["y"] = cfg.windowY, ["w"] = cfg.windowW, ["h"] = cfg.windowH },
      ["draggable"] = true,
      ["enabled"]   = true,
      ["visible"]   = true,
      ["hasCursor"] = true,
      ["modal"]     = false,
      ["resizable"] = true,
      ["zOrder"]    = cfg.zOrder,
      ["text"]      = cfg.title,
    },
    ["skin"] = self:_buildWindowSkin(),
    ["children"] = children,
  }

  local out = "dialog = " .. serialize(root) .. "\n"
  return out
end

------------------------------------------------------------
-- Write to file
------------------------------------------------------------
-- Write relative to Saved Games\DCS...
function DialogChecklistBuilder:write(relPath)
    local base = LockOn_Options.script_path
    local full = lfs.normpath(base .. relPath)
    
    if self.cfg.rebuild then
        -- ensure parent folder exists
        local folder = full:match("^(.*)[/\\][^/\\]+$")
        if folder then
            lfs.mkdir(folder)
        end

        local f, err = io.open(full, "wb")
        if not f then
            error("Failed to open " .. tostring(full) .. ": " .. tostring(err))
        end
        f:write(self:build())
        f:close()
        return full
    else -- still return the filename, but don't write a new file
        return full
    end
end

------------------------------------------------------------
-- Return the class
------------------------------------------------------------
return DialogChecklistBuilder

