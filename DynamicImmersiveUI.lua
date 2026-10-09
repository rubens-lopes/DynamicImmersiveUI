-- Hides the whole UI, the way Alt+Z does, unless you're in combat, have a
-- living target or have a window open. Out of combat the map, the loot
-- window and bags show on their own, and chat works with the UI hidden. The
-- breath bar, tooltips and quest progress text always show.
-- Optionally hides your arrow on the world map.
--
-- How it works, found with a probe on WoW Forever:
-- - SetUIVisibility works from an addon out of combat, and
--   PLAYER_REGEN_DISABLED fires before combat lockdown, so the UI is back in
--   time for every fight.
-- - Show and hide decisions wait a frame (C_Timer.After(0)): showing the UI
--   from inside a window's Show closes that window again.
-- - A window shown alone is moved onto the stage, a frame that stands in for
--   UIParent: same size and scale, never hidden. Parenting it to nil fails:
--   Blizzard's panel manager resets the map's scale and it ends up off screen.

local ADDON_NAME, ns = ...
local TITLE = "Dynamic Immersive UI"
local TAG = "|cff33ccff" .. TITLE .. ":|r "
-- Seconds chat stays visible after you stop typing.
local CHAT_LINGER = 5

-- Every saved switch, in the order the options panel shows them. All start on
-- unless marked off = true.
local OPTIONS = {
    { key = "hideUI", command = "hide", label = "Hide the UI out of combat",
      help = "Hides the whole UI, like Alt+Z, while you're out of combat. It comes back as soon as a fight starts. "
          .. "Esc brings it back until something changes; Esc again opens the game menu as usual." },
    { key = "target", command = "target", label = "A target brings the UI back",
      help = "Shows the UI while you have a living target, so you see its frame and your action bars. "
          .. "A dead target doesn't count: only the loot window shows." },
    { key = "solo", command = "solo", label = "Map, loot window and bags on their own",
      help = "Out of combat, the world map, the loot window and your bags show with the rest of the UI still hidden. "
          .. "So does any window you open by clicking a minimap button. Esc closes them. Turn this off to have them bring the whole UI back. Other windows (character sheet, spellbook, "
          .. "quests, vendors…) always bring the UI back." },
    { key = "minimap", command = "minimap", label = "Minimap always visible",
      help = "Keeps the minimap on screen while the rest of the UI is hidden. Turn this off to hide it with the UI." },
    { key = "arrow", command = "arrow", label = "Hide your arrow on the world map",
      help = "Hides the arrow that marks where you are on the world map, so you find your way like a traveller. "
          .. "Party and raid members still show." },
}

-- Replaced by the saved table on ADDON_LOADED.
local settings = {}
for _, option in ipairs(OPTIONS) do settings[option.key] = not option.off end

local warned = {}
local lastError
local loaded = false
local inCombat = false
-- True while we're the ones showing or hiding the UI.
local ours = false
-- Blizzard showed the UI itself (Esc or Alt+Z). Kept until the next change.
local manual = false
-- A bag key pressed while the UI was hidden: { name, fn, arg }.
local pendingBag
-- A window (character sheet, spellbook…) opened while the UI was hidden. It
-- closes when the UI comes back, so it's reopened a frame later: { name, frame }.
local pendingPanel
local reopening = false
-- Chat: the edit box being typed in, and until when chat stays after typing.
local chatBox
local chatUntil = 0

local function Say(msg) print(TAG .. msg) end

local function Warn(what, reason)
    lastError = ("couldn't %s (%s)"):format(what, reason)
    if warned[what] then return end
    warned[what] = true
    print(("|cffff8800%s:|r %s"):format(TITLE, lastError))
end

-- Runs fn, warning once per kind of failure instead of raising.
local function Try(what, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then Warn(what, tostring(err)) end
    return ok
end

local function SetUI(show)
    ours = true
    Try(show and "show the UI" or "hide the UI", SetUIVisibility, show)
    ours = false
end

---------------------------------------------------------------------------
-- Windows that show alone
---------------------------------------------------------------------------

local BAGS = { "ContainerFrameCombinedBags" }
for i = 1, 13 do BAGS[#BAGS + 1] = "ContainerFrame" .. i end
local SOLO = { "WorldMapFrame", "LootFrame" }
for _, name in ipairs(BAGS) do SOLO[#SOLO + 1] = name end
local isSolo = {}
for _, name in ipairs(SOLO) do isSolo[name] = true end
local isBag = {}
for _, name in ipairs(BAGS) do isBag[name] = true end
-- Windows opened by a click on something shown with the UI hidden (a minimap
-- button, say) also show on their own: frame -> name. Cleared when they close.
local extra = {}

-- Always visible, even with the UI hidden: the breath bar (mirror timers),
-- tooltips, and the yellow quest progress text (UIErrorsFrame, which also
-- shows the red error messages).
local ALWAYS = {
    "MirrorTimerContainer", "MirrorTimer1", "MirrorTimer2", "MirrorTimer3",
    "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefTooltip", "UIErrorsFrame",
    -- Lua error popups, so a bug isn't invisible.
    "ScriptErrorsFrame",
}

-- Also always visible while the minimap option is on. The cluster holds the
-- minimap; Minimap itself counts only if something moved it out.
local MINIMAP = { "MinimapCluster", "Minimap" }

local function Solo(name, frame)
    return settings.solo and not inCombat and (isSolo[name] or (frame ~= nil and extra[frame] ~= nil))
end

-- One stage per strata. SetParent hands the new parent's strata down to the
-- frame and everything in it; setting the frame's own strata back afterwards
-- doesn't reach its children, and a bag ends up drawn over its own buttons.
-- On a stage of its own strata, nothing needs setting back.
local stages = {}
local isStage = {}

local function GetStage(strata)
    local stage = stages[strata]
    if not stage then
        stage = CreateFrame("Frame", "DynamicImmersiveUIStage" .. strata)
        stage:SetAllPoints(UIParent)
        stage:SetFrameStrata(strata)
        stages[strata] = stage
        isStage[stage] = true
    end
    stage:SetScale(UIParent:GetScale())
    return stage
end

-- frame -> { name, parent, alpha, strata, solo } while it sits on a stage.
-- solo: a window that Esc closes.
local staged = {}

local function Stage(name, frame, solo)
    if staged[frame] then return end
    if frame:IsProtected() and InCombatLockdown() then return end
    local saved = { name = name, parent = frame:GetParent(), alpha = frame:GetAlpha(),
        strata = frame:GetFrameStrata(), solo = solo }
    if Try("show " .. name .. " on its own", frame.SetParent, frame, GetStage(saved.strata)) then
        staged[frame] = saved
    end
end

local function Unstage(frame)
    local saved = staged[frame]
    if not saved then return end
    if frame:IsProtected() and InCombatLockdown() then return end
    staged[frame] = nil
    Try("put " .. saved.name .. " back", function()
        frame:SetParent(saved.parent)
        -- Only frames that had a strata of their own, like tooltips: a bag
        -- is already right, and setting it would cover its buttons.
        if frame:GetFrameStrata() ~= saved.strata then frame:SetFrameStrata(saved.strata) end
        frame:SetAlpha(saved.alpha)
    end)
end

local function ChatActive()
    if chatBox and chatBox:HasFocus() then return true end
    return GetTime() < chatUntil
end

-- While the UI is hidden, open solo windows and the ALWAYS frames sit on the
-- stage, and so does
-- every chat frame and edit box, faded out unless you're typing. Chat has to
-- be there before Enter is pressed: moving an edit box and focusing it
-- yourself breaks sending (ChatFrameEditBox.lua).
local function SyncStage()
    local hidden = not UIParent:IsShown()
    local want = {}
    local solo = {}
    local chats = {}
    if hidden then
        for _, name in ipairs(SOLO) do
            local frame = _G[name]
            if frame and frame:IsShown() and Solo(name) then want[frame], solo[frame] = name, true end
        end
        for frame, name in pairs(extra) do
            if frame:IsShown() and Solo(name, frame) then want[frame], solo[frame] = name, true end
        end
        -- Only the ones directly under UIParent: a mirror timer inside its
        -- container moves with it.
        local function Keep(names)
            for _, name in ipairs(names) do
                local frame = _G[name]
                if type(frame) == "table" and frame.GetParent and (staged[frame] or frame:GetParent() == UIParent) then
                    want[frame] = name
                end
            end
        end
        Keep(ALWAYS)
        if settings.minimap then Keep(MINIMAP) end
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            for _, name in ipairs({ "ChatFrame" .. i, "ChatFrame" .. i .. "EditBox" }) do
                local frame = _G[name]
                -- Once on the stage their parent isn't UIParent any more.
                if frame and (staged[frame] or frame:GetParent() == UIParent) then
                    want[frame] = name
                    chats[#chats + 1] = frame
                end
            end
        end
        for frame, name in pairs(want) do Stage(name, frame, solo[frame]) end
        local alpha = ChatActive() and 1 or 0
        for _, frame in ipairs(chats) do
            if staged[frame] then frame:SetAlpha(alpha) end
        end
    end
    for frame in pairs(staged) do
        if not want[frame] then Unstage(frame) end
    end
end

---------------------------------------------------------------------------
-- What brings the UI back
---------------------------------------------------------------------------

-- Windows that show the UI while open. Load-on-demand ones are hooked once
-- they exist; any other window opened through ShowUIPanel is added to panels.
local WINDOWS = {
    "WorldMapFrame", "LootFrame", "CharacterFrame", "PlayerSpellsFrame", "SpellBookFrame", "FriendsFrame",
    "CommunitiesFrame", "CollectionsJournal", "ProfessionsFrame", "GameMenuFrame", "GossipFrame",
    "QuestFrame", "QuestLogFrame", "MerchantFrame", "ClassTrainerFrame", "TaxiFrame", "MailFrame", "BankFrame",
    "TradeFrame", "SettingsPanel", "AddonList", "AuctionHouseFrame", "MacroFrame", "PVEFrame", "PVPFrame",
    "HelpFrame", "StaticPopup1",
}
for _, name in ipairs(BAGS) do WINDOWS[#WINDOWS + 1] = name end

-- frame -> name
local panels = {}

local function OpenWindow()
    for _, name in ipairs(WINDOWS) do
        local frame = _G[name]
        if type(frame) == "table" and frame.IsShown and frame:IsShown() and not Solo(name, frame) then return name end
    end
    for frame, name in pairs(panels) do
        if frame:IsShown() and not Solo(name, frame) then return name end
    end
    -- Solo off: a window from a minimap click brings the UI back.
    for frame, name in pairs(extra) do
        if frame:IsShown() and not Solo(name, frame) then return name end
    end
end

-- A dead target doesn't count. If the client keeps it secret, count it.
local function LiveTarget()
    if not UnitExists("target") then return false end
    local dead = UnitIsDead("target")
    if issecretvalue and issecretvalue(dead) then return true end
    return not dead
end

-- Why the UI should show right now, or nil.
local function Wanted()
    if not settings.hideUI then return "hiding is off" end
    if inCombat then return "combat" end
    if pendingBag then return "bag key" end
    if pendingPanel then return "reopening " .. pendingPanel.name end
    if manual then return "shown with Esc or Alt+Z" end
    if settings.target and LiveTarget() then return "target" end
    local window = OpenWindow()
    if window then return "window " .. window end
end

local EvaluateNow

-- Bags refuse to open or close while the UI is hidden. Show it, run the bag
-- key, move open bags onto the stage and hide it again, all in one frame, so
-- the UI never appears.
local function BagAlone()
    local bag = pendingBag
    pendingBag = nil
    -- Repeating a toggle with a bag open closes the bags and Blizzard reopens
    -- the backpack in the same call: close them ourselves.
    local open = false
    for _, name in ipairs(BAGS) do
        local frame = _G[name]
        if frame and frame:IsShown() then open = true end
    end
    local fn = bag.fn
    if open and bag.name:find("^Toggle") and CloseAllBags then fn = CloseAllBags end
    SetUI(true)
    Try("open your bags", fn, bag.arg)
    for _, name in ipairs(BAGS) do
        local frame = _G[name]
        if frame and frame:IsShown() then Stage(name, frame, true) end
    end
    SetUI(false)
end

local function ReopenPanel()
    local panel = pendingPanel
    pendingPanel = nil
    reopening = false
    if panel and not panel.frame:IsShown() then Try("reopen " .. panel.name, ShowUIPanel, panel.frame) end
    EvaluateNow()
end

EvaluateNow = function()
    if not loaded then return end
    if pendingBag and settings.solo and not UIParent:IsShown() and not inCombat then BagAlone() end
    local why = Wanted()
    if why and not UIParent:IsShown() then
        SetUI(true)
    elseif not why and UIParent:IsShown() and not InCombatLockdown() then
        SetUI(false)
    end
    -- Solo off: the UI is back, so the bag key works now.
    if pendingBag and UIParent:IsShown() then
        local bag = pendingBag
        pendingBag = nil
        Try("open your bags", bag.fn, bag.arg)
    end
    -- The panel manager closes the window as the UI comes back
    -- (UIParentPanelManager SetUIPanel); reopen it a frame later.
    if pendingPanel and UIParent:IsShown() and not reopening then
        reopening = true
        C_Timer.After(0, ReopenPanel)
    end
    SyncStage()
end

-- One evaluation per frame, after Blizzard finished whatever triggered it.
local queued = false
local function Evaluate()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        EvaluateNow()
    end)
end

---------------------------------------------------------------------------
-- Hooks
---------------------------------------------------------------------------

local hooked = {}
-- A click on something shown with the UI hidden is in progress: windows it
-- opens join extra. before: UIParent's children shown when it started.
local clicking = false
local clickId = 0
local before

-- A window shown while the UI is hidden is invisible: show the UI and reopen it.
local function NoteHiddenPanel(name, frame)
    if clicking then extra[frame] = name end
    if settings.hideUI and not UIParent:IsShown() and not ours and not inCombat and not Solo(name)
        and not pendingPanel then
        pendingPanel = { name = name, frame = frame }
    end
end

local function HookWindow(name, frame)
    if hooked[frame] then return end
    hooked[frame] = true
    -- Show runs even while the parent is hidden; OnShow doesn't.
    hooksecurefunc(frame, "Show", function()
        NoteHiddenPanel(name, frame)
        Evaluate()
    end)
    frame:HookScript("OnHide", function()
        if staged[frame] then Unstage(frame) end
        extra[frame] = nil
        if name == "GameMenuFrame" then manual = false end
        Evaluate()
    end)
end

local function HookWindows()
    for _, name in ipairs(WINDOWS) do
        local frame = _G[name]
        if type(frame) == "table" and frame.HookScript then HookWindow(name, frame) end
    end
end

local BAG_FUNCTIONS = { "ToggleAllBags", "OpenAllBags", "ToggleBackpack", "OpenBackpack", "ToggleBag" }

local function HookBags()
    for _, name in ipairs(BAG_FUNCTIONS) do
        local fn = _G[name]
        if type(fn) == "function" then
            hooksecurefunc(name, function(arg)
                if settings.hideUI and not UIParent:IsShown() and not ours then
                    pendingBag = { name = name, fn = fn, arg = arg }
                    Evaluate()
                end
            end)
        end
    end
end

local function HookChat()
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local box = _G["ChatFrame" .. i .. "EditBox"]
        if box then
            box:HookScript("OnEditFocusGained", function()
                chatBox = box
                Evaluate()
            end)
            box:HookScript("OnEditFocusLost", function()
                chatUntil = GetTime() + CHAT_LINGER
                C_Timer.After(CHAT_LINGER + 0.1, Evaluate)
            end)
        end
    end
end

local function HookPanels()
    if type(ShowUIPanel) ~= "function" then return end
    hooksecurefunc("ShowUIPanel", function(frame)
        if type(frame) ~= "table" or not frame.IsShown then return end
        local name = frame:GetName() or "unnamed window"
        HookWindows()
        if not panels[frame] then panels[frame] = name end
        -- Its Show ran before the hook existed: note this first opening here.
        if not hooked[frame] then
            HookWindow(name, frame)
            if frame:IsShown() then NoteHiddenPanel(name, frame) end
        end
        Evaluate()
    end)
end

-- Clicks on the stage: the minimap and its addon buttons, bags, the map, chat.
local function OnStage(region)
    while region do
        if isStage[region] then return true end
        region = region.GetParent and region:GetParent()
    end
    return false
end

local function MouseOnStage()
    local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
    for _, region in ipairs(foci) do
        if OnStage(region) then return true end
    end
    return false
end

local function ShownChildren()
    local shown = {}
    for _, child in ipairs({ UIParent:GetChildren() }) do
        -- Forbidden frames (Blizzard's secure ones) error on anything but
        -- IsForbidden. Windows take the mouse; helper frames mostly don't.
        if not (child.IsForbidden and child:IsForbidden()) and child:IsShown()
            and not (child.IsMouseEnabled and not child:IsMouseEnabled()) then
            shown[child] = true
        end
    end
    return shown
end

-- Only for as long as it's open: shown again later, on its own, it's none of
-- our business (it may not even be a window).
local extraHooked = {}
local function HookExtra(frame)
    if hooked[frame] or extraHooked[frame] then return end
    extraHooked[frame] = true
    frame:HookScript("OnHide", function()
        if not extra[frame] then return end
        extra[frame] = nil
        if staged[frame] then Unstage(frame) end
        Evaluate()
    end)
end

-- Windows the click opened without ShowUIPanel (most addon windows): any of
-- UIParent's children shown since the click started.
local function ScanClick()
    if not before then return end
    for child in pairs(ShownChildren()) do
        if not before[child] then
            before[child] = true
            extra[child] = child:GetName() or "a window"
            HookExtra(child)
        end
    end
    Evaluate()
end

local function ClickStarted()
    if UIParent:IsShown() or inCombat or not settings.hideUI or not MouseOnStage() then return end
    clickId = clickId + 1
    clicking = true
    before = ShownChildren()
end

local function ClickEnded()
    if not clicking then return end
    local id = clickId
    C_Timer.After(0, ScanClick)
    -- Some windows open a moment later.
    C_Timer.After(0.2, function()
        ScanClick()
        if id == clickId then clicking, before = false, nil end
    end)
end

-- Esc with a window on its own: Blizzard shows the UI instead of closing it
-- (Game.lua). Close the window ourselves and keep the UI hidden.
local function CloseSolo()
    local open = {}
    for frame, saved in pairs(staged) do
        if saved.solo and frame:IsShown() then open[frame] = saved.name end
    end
    if not next(open) then return false end
    for frame, name in pairs(open) do
        if isBag[name] and CloseAllBags then
            Try("close your bags", CloseAllBags)
        elseif name == "LootFrame" and CloseLoot then
            Try("close the loot window", CloseLoot)
        elseif panels[frame] and HideUIPanel then
            Try("close " .. name, HideUIPanel, frame)
        end
        if frame:IsShown() then Try("close " .. name, frame.Hide, frame) end
    end
    Evaluate()
    return true
end

---------------------------------------------------------------------------
-- World map arrow
---------------------------------------------------------------------------

-- Your arrow is a pin from this pool (a UnitPositionFrame).
local ARROW_TEMPLATE = "GroupMembersPinTemplate"
local arrowHidden = setmetatable({}, { __mode = "k" })

local function ApplyArrow()
    local map = WorldMapFrame
    local pool = map and map.pinPools and map.pinPools[ARROW_TEMPLATE]
    if not (pool and pool.EnumerateActive) then return end
    for pin in pool:EnumerateActive() do
        if settings.arrow then
            pin:SetAlpha(0)
            arrowHidden[pin] = true
        elseif arrowHidden[pin] then
            pin:SetAlpha(1)
            arrowHidden[pin] = nil
        end
    end
end

local function HookMap()
    local map = WorldMapFrame
    if not map then return end
    if map.AcquirePin then
        hooksecurefunc(map, "AcquirePin", function(_, template)
            if template == ARROW_TEMPLATE then Try("hide your map arrow", ApplyArrow) end
        end)
    end
    map:HookScript("OnShow", function()
        C_Timer.After(0, function() Try("hide your map arrow", ApplyArrow) end)
    end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local EVENTS = {}

function EVENTS.ADDON_LOADED(name)
    if name == ADDON_NAME then
        DynamicImmersiveUIDB = DynamicImmersiveUIDB or {}
        settings = DynamicImmersiveUIDB
        for _, option in ipairs(OPTIONS) do
            if settings[option.key] == nil then settings[option.key] = not option.off end
        end
    end
    HookWindows()
end

function EVENTS.PLAYER_LOGIN()
    HookWindows()
    HookBags()
    HookChat()
    HookPanels()
    HookMap()
    UIParent:HookScript("OnShow", function()
        if ours or not settings.hideUI then return end
        -- Esc or Alt+Z with a window on its own closes the window.
        if CloseSolo() then return end
        -- Otherwise keep the UI until the next change.
        manual = true
    end)
    loaded = true
end

function EVENTS.PLAYER_ENTERING_WORLD()
    inCombat = InCombatLockdown() and true or false
    Evaluate()
end

function EVENTS.PLAYER_REGEN_DISABLED()
    inCombat = true
    manual = false
    -- Not queued: this is the last moment before lockdown.
    EvaluateNow()
end

function EVENTS.PLAYER_REGEN_ENABLED()
    inCombat = false
    Evaluate()
end

function EVENTS.PLAYER_TARGET_CHANGED()
    manual = false
    Evaluate()
end

-- The target dying doesn't change the target.
function EVENTS.UNIT_HEALTH() Evaluate() end
EVENTS.UNIT_FLAGS = EVENTS.UNIT_HEALTH

EVENTS.GLOBAL_MOUSE_DOWN = ClickStarted
EVENTS.GLOBAL_MOUSE_UP = ClickEnded

local listener = CreateFrame("Frame")
for event in pairs(EVENTS) do
    if event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
        listener:RegisterUnitEvent(event, "target")
    else
        -- pcall: an event this client doesn't have only loses its feature.
        pcall(listener.RegisterEvent, listener, event)
    end
end
listener:SetScript("OnEvent", function(_, event, ...) EVENTS[event](...) end)

---------------------------------------------------------------------------
-- Settings and commands
---------------------------------------------------------------------------

-- Shared with Options.lua, which builds the panel from the same list.
ns.TITLE = TITLE
ns.OPTIONS = OPTIONS
function ns.Get(key) return settings[key] end
function ns.Set(key, value)
    settings[key] = value
    manual = false
    if key == "arrow" then Try("hide your map arrow", ApplyArrow) end
    EvaluateNow()
end

local function Help()
    Say("commands")
    print("  /dui-help - show this list")
    print("  /dui-options - open the options panel, with a longer explanation of each switch")
    print("  /dui-status - show what the addon sees (include it in bug reports)")
    for _, option in ipairs(OPTIONS) do
        print(("  /dui-%s [on|off] - %s (now %s)"):format(
            option.command, option.label:lower(), settings[option.key] and "on" or "off"))
    end
end

-- /dui-<command> [on|off]: no argument toggles.
local function MakeToggle(key)
    local option
    for _, o in ipairs(OPTIONS) do
        if o.key == key then option = o end
    end
    return function(arg)
        arg = (arg or ""):lower():match("^%s*(.-)%s*$")
        local value
        if arg == "on" then
            value = true
        elseif arg == "off" then
            value = false
        elseif arg == "" then
            value = not settings[option.key]
        else
            Say(("usage: /dui-%s [on|off]"):format(option.command))
            return
        end
        ns.Set(option.key, value)
        Say(("%s: %s."):format(option.label, value and "on" or "off"))
    end
end

local function Status()
    -- Also kept in the saved variables (written on /reload or logout), for
    -- output too long to screenshot.
    local lines = {}
    settings.lastStatus = lines
    local function Line(line)
        lines[#lines + 1] = line
        print(line)
    end
    Line(TAG .. (InCombatLockdown() and "in combat lockdown" or (inCombat and "in combat" or "out of combat")))
    for _, option in ipairs(OPTIONS) do
        Line(("  %s: %s"):format(option.label, settings[option.key] and "on" or "off"))
    end
    Line(("  UI shown: %s, because: %s"):format(tostring(UIParent:IsShown()), Wanted() or "nothing"))
    local names = {}
    for _, saved in pairs(staged) do names[#names + 1] = saved.name end
    table.sort(names)
    Line("  on their own: " .. (#names > 0 and table.concat(names, ", ") or "nothing"))
    names = {}
    for frame, name in pairs(extra) do names[#names + 1] = name .. (frame:IsShown() and "" or " (closed)") end
    table.sort(names)
    Line("  opened by a click: " .. (#names > 0 and table.concat(names, ", ") or "nothing"))
    local dead = UnitIsDead("target")
    Line(("  target: %s, dead: %s"):format(tostring(UnitExists("target")),
        issecretvalue and issecretvalue(dead) and "secret" or tostring(dead)))
    Line("  last error: " .. (lastError or "none"))
end

-- Options.lua sets ns.OpenOptions once the panel is registered.
local function Options()
    -- The panel is part of the UI: bring it back first, or the panel manager
    -- closes the panel as the UI comes back. The open panel keeps it shown.
    if not UIParent:IsShown() and not InCombatLockdown() then SetUI(true) end
    if ns.OpenOptions then return ns.OpenOptions() end
    Say("the options panel isn't available on this client. Use /dui-help for the commands.")
end

SLASH_DUIHELP1 = "/dui-help"
SlashCmdList.DUIHELP = Help
SLASH_DUIOPTIONS1 = "/dui-options"
SlashCmdList.DUIOPTIONS = Options
SLASH_DUIHIDE1 = "/dui-hide"
SlashCmdList.DUIHIDE = MakeToggle("hideUI")
SLASH_DUITARGET1 = "/dui-target"
SlashCmdList.DUITARGET = MakeToggle("target")
SLASH_DUISOLO1 = "/dui-solo"
SlashCmdList.DUISOLO = MakeToggle("solo")
SLASH_DUIMINIMAP1 = "/dui-minimap"
SlashCmdList.DUIMINIMAP = MakeToggle("minimap")
SLASH_DUIARROW1 = "/dui-arrow"
SlashCmdList.DUIARROW = MakeToggle("arrow")
SLASH_DUISTATUS1 = "/dui-status"
SlashCmdList.DUISTATUS = Status
