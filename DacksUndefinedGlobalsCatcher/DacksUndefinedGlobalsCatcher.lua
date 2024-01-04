local addon = {
    Name = 'DacksUndefinedGlobalsCatcher',
    msgwin = nil
}

local _G = _G
local setmetatable = _G.setmetatable
local type = _G.type
local debugTraceback = _G.debug and _G.debug.traceback
local EVENT_MANAGER = _G.GetEventManager()
local ZO_GetCallstackFunctionNames = _G.ZO_GetCallstackFunctionNames
local EVENT_ADD_ON_LOADED = _G.EVENT_ADD_ON_LOADED
local SLASH_COMMANDS = _G.SLASH_COMMANDS
local ipairs = _G.ipairs
local string_format = _G.string and _G.string.format
local zo_strsub = _G.zo_strsub
local zo_abs = _G.zo_abs
local math_frexp = _G.math and _G.math.frexp
local reported = {}
setmetatable(reported, {
    __index = function ()
        return 0
    end
})

local ignoreGlobals = {
    'ActionButtonDecoration',
    'ActionButton1Decoration',
    'ActionButton2Decoration',
    'ActionButton3Decoration',
    'ActionButton4Decoration',
    'ActionButton5Decoration',
    'ActionButton6Decoration',
    'ActionButton7Decoration',
    'ActionButton8Decoration',
    'ActionButton9Decoration',
    'ActionButton10Decoration',
    'ActionButton11Decoration',
    'ActionButton12Decoration',
    'ActionButton13Decoration',
    'ActionButton14Decoration',
    'ActionButton15Decoration',
    'ActionButton16Decoration',
    'ActionButton17Decoration',
    'ActionButton18Decoration',
    'ActionButton19Decoration',
    'ActionButton20Decoration',
    'ActionButton21Decoration',
    'ActionButton22Decoration',
    'ActionButton23Decoration',
    'AdvancedFilters',
    'BRACKET_COMMANDS',
    'ComparativeTooltip1Divider1',
    'ComparativeTooltip2Divider1',
    'ComparativeTooltip1SellPrice2',
    'ComparativeTooltip2SellPrice2',
    'GridList',
    'QuickslotButtonDecoration',
    'QuickslotButton1Decoration',
    'QuickslotButton2Decoration',
    'QuickslotButton3Decoration',
    'QuickslotButton4Decoration',
    'QuickslotButton5Decoration',
    'QuickslotButton6Decoration',
    'QuickslotButton7Decoration',
    'QuickslotButton8Decoration',
    'QuickslotButton9Decoration',
    'QuickslotButton10Decoration',
    'QuickslotButton11Decoration',
    'QuickslotButton12Decoration',
    'QuickslotButton13Decoration',
    'QuickslotButton14Decoration',
    'QuickslotButton15Decoration',
    'QuickslotButton16Decoration',
    'QuickslotButton17Decoration',
    'QuickslotButton18Decoration',
    'QuickslotButton19Decoration',
    'QuickslotButton20Decoration',
    'QuickslotButton21Decoration',
    'QuickslotButton22Decoration',
    'QuickslotButton23Decoration',
    'IIfA',
    'InventoryGridView',
    'ItemTooltipDivider1',
    'ItemTooltipCondition',
    'ItemTooltipEquippedInfo',
    'ItemTooltipSellPrice1',
    'ItemTooltipSellPrice2',
    'ITEM_TRAIT_TYPE_SPECIAL_STAT',
    'NOTIFICATION_ICONS_CONSOLE',
    'PREVIEW_UPDATE_INTERVAL_MS',
    'PULSES',
    'Roomba',
    'SetTrack',
    'WriteToInterfaceLog',
    'g_currentPlayerName',
    'g_currentPlayerUserId',
}

local function createIgnoreLookup(ignoreList)
    local lookup = {}
    for _, v in ipairs(ignoreList) do
        lookup[v] = true
    end
    return lookup
end

local ignoreLookup = createIgnoreLookup(ignoreGlobals)

local function formatMessage(formatStr, reportedKey, key, traceback, functionNames)
    local callStackInfo = '|c0000FFCall stack|r:\n'
    for i, functionName in ipairs(functionNames) do
        callStackInfo = callStackInfo..string_format('%d. %s\n', i, functionName)
    end
    local message = string_format(formatStr, reportedKey, key)..'\n'..traceback..'\n'..callStackInfo
    return message
end

local function toggleMsgWindow()
    addon.msgwin:ToggleHidden()
end

local function globalmiss(_, key)
    -- Check if the key is in the ignore list or starts with certain prefixes
    if not key or ignoreLookup[key] or zo_strsub(key, 1, 1) == '_' or zo_strsub(key, 1, 2) == 'ZO'
        or zo_strsub(key, 1, 3) == 'SI_' or zo_strsub(key, 1, 5) == 'FCOIS' then
        return
    end
    reported[key] = (reported[key] or 0) + 1
    local epsilon = 1e-6
    if zo_abs(math_frexp(reported[key]) - 0.5) > epsilon then
        return
    end
    if addon.msgwin == nil then
        return
    end
    local formatStr = type(key) == 'string' and '%3dx %q' or '%3dx %s'
    local traceback = debugTraceback('|cFF0000Undefined global|r:'..key, 2)
    local functionNames = ZO_GetCallstackFunctionNames(1) -- Exclude the current function
    local message = formatMessage(formatStr, reported[key], key, traceback, functionNames)
    addon.msgwin:AddText(message)
end

local function onLoad(eventCode, addOnName)
    if addOnName ~= addon.Name then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(addon.Name, eventCode)
    local libmw = _G.LibMsgWin
    addon.msgwin = libmw:CreateMsgWindow('DacksUndefinedGlobalsCatcherWindow', 'undefined globals')
    addon.msgwin:SetDimensions(700, 400)
    addon.msgwin:SetHidden(true)
    SLASH_COMMANDS['/undefs'] = toggleMsgWindow
    setmetatable(_G, {
        __index = globalmiss
    })
end

EVENT_MANAGER:RegisterForEvent(addon.Name, EVENT_ADD_ON_LOADED, onLoad)
