-- This is needed to make DXGUI work in the aircraft Lua environment
package.path = package.path..';./Scripts/?.lua;'
    ..'./Scripts/Common/?.lua;./Scripts/UI/?.lua;'
    .. './Scripts/UI/F10View/?.lua;'
    .. './Scripts/Speech/?.lua;'
    .. './dxgui/bind/?.lua;./dxgui/loader/?.lua;./dxgui/skins/skinME/?.lua;./dxgui/skins/common/?.lua;'
    .. './MissionEditor/modules/?.lua;'
    .. './Scripts/Debug/?.lua;'
    .. './Scripts/Input/?.lua;'


-- Load Object Modules from DCS Core. (More are available, these ones have been tested)
Window = require('Window')
Button = require('Button')
CheckBox = require('CheckBox')
ColorTextStatic = require("ColorTextStatic")
ComboList = require("ComboList")
Skin = require("Skin")

