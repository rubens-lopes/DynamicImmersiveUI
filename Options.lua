-- The options, in two places:
-- - a page under Options > AddOns, built from Blizzard's own controls: one
--   checkbox per switch in ns.OPTIONS under its heading, what it does in the
--   tooltip, and the Defaults button.
-- - a quick menu of the same switches, from the addon button on the minimap.
--   The minimap stays visible, so the switches can be changed without
--   bringing the UI back.

local _, ns = ...

local VARIABLE = "DYNAMIC_IMMERSIVE_UI_"

local function Tooltip(option)
    return option.help .. "\n\n|cff808080/dui-" .. option.command .. " [on|off]|r"
end

-- The page reads each switch through a proxy setting; a switch set elsewhere
-- (a /dui- command, the quick menu) tells it to read again.
local settings = {}
ns.OnSet = function(key)
    if settings[key] then settings[key]:NotifyUpdate() end
end

if Settings and Settings.RegisterVerticalLayoutCategory then
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.TITLE)
    local boolean = Settings.VarType and Settings.VarType.Boolean or "boolean"
    for _, option in ipairs(ns.OPTIONS) do
        if option.section and layout and CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(option.section))
        end
        local setting = Settings.RegisterProxySetting(category, VARIABLE .. option.key:upper(), boolean,
            option.label, not option.off,
            function() return ns.Get(option.key) and true or false end,
            function(value) ns.Set(option.key, value and true or false) end)
        Settings.CreateCheckbox(category, setting, Tooltip(option))
        settings[option.key] = setting
    end
    Settings.RegisterAddOnCategory(category)

    -- The panel goes to its first page when it shows. Opened with the UI
    -- hidden, it shows again after it went to our page: when it's staged, or
    -- reopened after the UI coming back closed it. Go to our page again then.
    local function Open() Settings.OpenToCategory(category:GetID()) end
    local waiting, hooked
    ns.OpenOptions = function()
        Open()
        if not (SettingsPanel and SettingsPanel.HookScript) then return end
        if not hooked then
            hooked = true
            SettingsPanel:HookScript("OnShow", function()
                if not waiting then return end
                waiting = false
                C_Timer.After(0, Open)
            end)
        end
        waiting = true
        -- If it never shows (combat), the next time it's opened isn't ours.
        C_Timer.After(1, function() waiting = false end)
    end
end

local function QuickMenu()
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return ns.ShowOptions() end
    MenuUtil.CreateContextMenu(AddonCompartmentFrame, function(_, root)
        root:CreateTitle(ns.TITLE)
        for _, option in ipairs(ns.OPTIONS) do
            local box = root:CreateCheckbox(option.label,
                function() return ns.Get(option.key) end,
                function() ns.Set(option.key, not ns.Get(option.key)) end)
            box:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, option.label)
                GameTooltip_AddNormalLine(tooltip, option.help)
            end)
        end
        root:CreateDivider()
        root:CreateButton("All options…", function() ns.ShowOptions() end)
    end)
end

-- The addon button on the minimap (the .toc names these). The compartment's
-- own menu closes after the click: open ours a frame later.
function DynamicImmersiveUI_OnAddonCompartmentClick()
    C_Timer.After(0, QuickMenu)
end

function DynamicImmersiveUI_OnAddonCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip_SetTitle(GameTooltip, ns.TITLE)
    GameTooltip_AddNormalLine(GameTooltip, "Click to turn its switches on or off.")
    GameTooltip:Show()
end

function DynamicImmersiveUI_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
