local addon =
{
    Name = "DacksUndefinedGlobalsCatcher"
}

local _G = _G;
local setmetatable = _G.setmetatable;
local type = _G.type;
local debugTraceback = _G.debug and _G.debug.traceback;
local EVENT_MANAGER = _G.GetEventManager();
local ZO_GetCallstackFunctionNames = _G.ZO_GetCallstackFunctionNames;
local EVENT_ADD_ON_LOADED = _G.EVENT_ADD_ON_LOADED;
local slcmds = _G.SLASH_COMMANDS;
local ipairs = _G.ipairs;
local string_format = _G.string and _G.string.format;
local zo_strsub = _G.zo_strsub;
local math_frexp = _G.math and _G.math.frexp;
local msgwin = nil;


local reported = {};
setmetatable(reported, {
    __index = function()
        return 0
    end,
});

local globalmiss = function(tab, key)
    if not key or zo_strsub(key, 1, 2) == "ZO" or zo_strsub(key, 1, 3) == "SI_" then
        return
    end;

    reported[key] = (reported[key] or 0) + 1;

    if math_frexp(reported[key]) ~= 0.5 then
        return
    end;

    if msgwin == nil then return end;

    local formatStr = type(key) == "string" and "%3dx %q" or "%3dx %s";

    local traceback = debugTraceback("Undefined global: " .. key, 2);

    -- Get the call stack function names
    local functionNames = ZO_GetCallstackFunctionNames(1); -- Exclude the current function

    -- Add the call stack information to the error message
    local callStackInfo = "Call stack:\n";

    for i, functionName in ipairs(functionNames) do
        callStackInfo = callStackInfo .. string_format("%d. %s\n", i, functionName)
    end;

    ---@type ESOUSERDATATYPE
    msgwin:AddText(string_format(formatStr, reported[key], key) .. "\n" .. traceback .. "\n" .. callStackInfo);
end;

local onLoad = function(eventCode, addOnName)
    if addOnName ~= addon.Name then return end;

    EVENT_MANAGER:UnregisterForEvent(addon.Name, eventCode);

    ---@class LibMsgWin-1.0
    local libmw = _G.LibMsgWin;

    ---@type object : tlw
    msgwin = libmw:CreateMsgWindow("DacksUndefinedGlobalsCatcherWindow", "undefined globals");
    msgwin:SetDimensions(700, 400);
    msgwin:SetHidden(true);

    slcmds["/undefs"] = function() msgwin:ToggleHidden() end;

    setmetatable(_G, { __index = globalmiss });
end;

EVENT_MANAGER:RegisterForEvent(addon.Name, EVENT_ADD_ON_LOADED, onLoad);
