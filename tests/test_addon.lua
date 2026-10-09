-- Loads the addon into a stubbed WoW API and checks when it hides and shows
-- the UI, and which frames it moves onto its stage.
-- Run from the repo root: luajit tests/test_addon.lua

local ADDON_FILE = "DynamicImmersiveUI.lua"
local ADDON_NAME = "DynamicImmersiveUI"

-- opts.saved   DynamicImmersiveUIDB as left by a previous session
-- opts.combat  in combat lockdown at login
local function Load(opts)
    opts = opts or {}
    local env = { time = 100, timers = {}, visibility = {}, calls = {}, lockdown = opts.combat or false }
    local G = setmetatable({}, { __index = _G })
    G._G = G
    env.G = G

    local frames = {}
    local function NewFrame(name, parent, shown)
        local f = { name = name, parent = parent, shown = shown ~= false, alpha = 1, scripts = {}, hooks = {},
            events = {}, strata = "MEDIUM", level = 1 }
        function f:GetName() return self.name end
        function f:IsShown() return self.shown end
        function f:IsVisible()
            local p = self
            while p do
                if not p.shown then return false end
                p = p.parent
            end
            return true
        end
        local function Run(self, script)
            for _, fn in ipairs(self.hooks[script] or {}) do fn(self) end
        end
        f.Run = Run
        function f:Show()
            if self.shown then return end
            self.shown = true
            Run(self, "OnShow")
        end
        function f:Hide()
            if not self.shown then return end
            self.shown = false
            Run(self, "OnHide")
        end
        -- Like the client, a new parent hands down its strata, and the frame
        -- and its children are renumbered from the parent's level.
        -- SetFrameStrata, below, changes only the frame itself.
        local function Renumber(frame, level, strata)
            frame.level = level
            frame.strata = strata
            for _, child in ipairs(frames) do
                if child.parent == frame then Renumber(child, level + 1, strata) end
            end
        end
        function f:SetParent(p)
            self.parent = p
            Renumber(self, p and p.level + 1 or 1, p and p.strata or "MEDIUM")
        end
        function f:GetFrameStrata() return self.strata end
        function f:SetFrameStrata(s) self.strata = s end
        function f:GetFrameLevel() return self.level end
        function f:SetFrameLevel(l) self.level = l end
        function f:GetChildren()
            local children = {}
            for _, child in ipairs(frames) do
                if child.parent == self then children[#children + 1] = child end
            end
            return unpack(children)
        end
        function f:GetParent() return self.parent end
        function f:SetAlpha(a) self.alpha = a end
        function f:GetAlpha() return self.alpha end
        function f:IsProtected() return false end
        function f:HookScript(script, fn)
            self.hooks[script] = self.hooks[script] or {}
            table.insert(self.hooks[script], fn)
        end
        function f:SetScript(script, fn) self.scripts[script] = fn end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:RegisterUnitEvent(event) self.events[event] = true end
        function f:SetAllPoints() end
        function f:SetScale() end
        function f:GetScale() return 1 end
        function f:HasFocus() return self.focus == true end
        frames[#frames + 1] = f
        if name then G[name] = f end
        return f
    end
    env.NewFrame = NewFrame

    local UIParent = NewFrame("UIParent", nil, true)
    env.UIParent = UIParent
    G.CreateFrame = function(_, name) return NewFrame(name, nil, true) end
    G.InCombatLockdown = function() return env.lockdown end
    G.GetTime = function() return env.time end
    G.C_Timer = { After = function(delay, fn)
        table.insert(env.timers, { at = env.time + delay, fn = fn })
    end }
    G.issecretvalue = function(v) return v == "SECRET" end
    G.NUM_CHAT_WINDOWS = 1
    G.hooksecurefunc = function(a, b, c)
        local tbl, name, hook = a, b, c
        if type(a) == "string" then tbl, name, hook = G, a, b end
        local original = tbl[name]
        tbl[name] = function(...)
            local r = { original(...) }
            hook(...)
            return unpack(r)
        end
    end

    -- Windows. The panel manager closes the character sheet when the UI
    -- comes back, like UIParentPanelManager's SetUIPanel.
    local map = NewFrame("WorldMapFrame", UIParent, false)
    env.arrow = { alpha = 1 }
    function env.arrow:SetAlpha(a) self.alpha = a end
    map.pinPools = { GroupMembersPinTemplate = { EnumerateActive = function()
        local done = false
        return function()
            if done then return nil end
            done = true
            return env.arrow
        end
    end } }
    function map:AcquirePin() end
    NewFrame("LootFrame", UIParent, false)
    NewFrame("CharacterFrame", UIParent, false)
    NewFrame("GameMenuFrame", UIParent, false)
    NewFrame("ContainerFrameCombinedBags", UIParent, false)
    NewFrame("ChatFrame1", UIParent, true)
    NewFrame("ChatFrame1EditBox", UIParent, true)
    NewFrame("GameTooltip", UIParent, false).strata = "TOOLTIP"
    NewFrame("UIErrorsFrame", UIParent, true)
    local cluster = NewFrame("MinimapCluster", UIParent, true)
    NewFrame("Minimap", cluster, true)
    local container = NewFrame("MirrorTimerContainer", UIParent, true)
    NewFrame("MirrorTimer1", container, false)

    G.SetUIVisibility = function(show)
        env.visibility[#env.visibility + 1] = show
        if show then
            UIParent:Show()
            G.CharacterFrame:Hide()
        else
            UIParent:Hide()
        end
    end
    G.ShowUIPanel = function(f)
        env.calls[#env.calls + 1] = "ShowUIPanel " .. f:GetName()
        f:Show()
    end
    G.HideUIPanel = function(f)
        env.calls[#env.calls + 1] = "HideUIPanel " .. f:GetName()
        f:Hide()
    end
    -- What the mouse is over.
    G.GetMouseFoci = function() return { env.mouse } end
    -- Bags refuse to open or close while the UI is hidden.
    local bags = G.ContainerFrameCombinedBags
    G.ToggleBackpack = function()
        env.calls[#env.calls + 1] = "ToggleBackpack"
        if not UIParent.shown then return end
        if bags.shown then bags:Hide() else bags:Show() end
    end
    G.CloseAllBags = function()
        env.calls[#env.calls + 1] = "CloseAllBags"
        if UIParent.shown then bags:Hide() end
    end

    env.unit = { exists = false, dead = false }
    G.UnitExists = function() return env.unit.exists end
    G.UnitIsDead = function() return env.unit.dead end
    G.SlashCmdList = {}
    G.DynamicImmersiveUIDB = opts.saved

    function env.Fire(event, ...)
        for _, f in ipairs(frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end
    -- Runs the timers due by now, plus any they queue for the same time.
    function env.Tick(seconds)
        env.time = env.time + (seconds or 0.02)
        local ran = true
        while ran do
            ran = false
            for i, t in ipairs(env.timers) do
                if t.at <= env.time then
                    table.remove(env.timers, i)
                    t.fn()
                    ran = true
                    break
                end
            end
        end
    end
    function env.Slash(name, arg) G.SlashCmdList[name](arg) end
    function env.OnStage(name)
        local parent = G[name].parent
        return parent ~= nil and parent.name ~= nil and parent.name:find("^DynamicImmersiveUIStage") ~= nil
    end

    local chunk = assert(loadfile(ADDON_FILE))
    setfenv(chunk, G)
    env.ns = {}
    G.print = function(...) env.printed = table.concat({ ... }, " ") end
    chunk(ADDON_NAME, env.ns)
    env.Fire("ADDON_LOADED", ADDON_NAME)
    env.Fire("PLAYER_LOGIN")
    env.Fire("PLAYER_ENTERING_WORLD")
    env.Tick()
    return env
end

local passed, failed = 0, 0
local function Test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("PASS  " .. name)
    else
        failed = failed + 1
        print("FAIL  " .. name .. "\n      " .. tostring(err))
    end
end
local function Eq(actual, expected, what)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(what, tostring(expected), tostring(actual)), 2)
    end
end

Test("hides the UI after login out of combat", function()
    local env = Load()
    Eq(env.UIParent.shown, false, "UI shown")
end)

Test("leaves the UI alone when logging in during combat", function()
    local env = Load({ combat = true })
    Eq(env.UIParent.shown, true, "UI shown")
end)

Test("shows the UI right away when combat starts, hides it after", function()
    local env = Load()
    env.Fire("PLAYER_REGEN_DISABLED")
    Eq(env.UIParent.shown, true, "UI shown before the next frame")
    env.lockdown = true
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown in combat")
    env.lockdown = false
    env.Fire("PLAYER_REGEN_ENABLED")
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown after combat")
end)

Test("a living target shows the UI, a dead one doesn't", function()
    local env = Load()
    env.unit.exists = true
    env.Fire("PLAYER_TARGET_CHANGED")
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown with a live target")
    env.unit.dead = true
    env.Fire("UNIT_HEALTH", "target")
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown with a dead target")
    env.unit.dead = "SECRET"
    env.Fire("UNIT_FLAGS", "target")
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown when death is secret")
end)

Test("/dui-target off: a target doesn't show the UI", function()
    local env = Load()
    env.Slash("DUITARGET", "off")
    env.unit.exists = true
    env.Fire("PLAYER_TARGET_CHANGED")
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown")
end)

Test("/dui-hide off shows the UI and keeps it", function()
    local env = Load()
    env.Slash("DUIHIDE", "off")
    Eq(env.UIParent.shown, true, "UI shown")
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown a frame later")
    Eq(env.G.DynamicImmersiveUIDB.hideUI, false, "saved setting")
end)

Test("saved settings survive a reload", function()
    local env = Load({ saved = { hideUI = false } })
    Eq(env.UIParent.shown, true, "UI shown")
    Eq(env.G.DynamicImmersiveUIDB.target, true, "new switch filled in")
end)

Test("Esc keeps the UI until the target changes", function()
    local env = Load()
    env.UIParent:Show() -- Blizzard, not the addon
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown after Esc")
    env.Fire("PLAYER_TARGET_CHANGED")
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown after a target change")
end)

Test("the map shows on its own, with the arrow hidden", function()
    local env = Load()
    env.G.WorldMapFrame:Show()
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown")
    Eq(env.OnStage("WorldMapFrame"), true, "map on the stage")
    Eq(env.arrow.alpha, 0, "arrow alpha")
    env.G.WorldMapFrame:Hide()
    env.Tick()
    Eq(env.G.WorldMapFrame.parent, env.UIParent, "map parent after closing")
end)

Test("/dui-arrow off shows the arrow again", function()
    local env = Load()
    env.G.WorldMapFrame:Show()
    env.Tick()
    env.Slash("DUIARROW", "off")
    Eq(env.arrow.alpha, 1, "arrow alpha")
end)

Test("/dui-solo off: the map brings the UI back", function()
    local env = Load()
    env.Slash("DUISOLO", "off")
    env.G.WorldMapFrame:Show()
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown")
    Eq(env.OnStage("WorldMapFrame"), false, "map on the stage")
end)

Test("the character sheet brings the UI back and is reopened", function()
    local env = Load()
    env.G.CharacterFrame:Show()
    env.Tick()
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown")
    Eq(env.G.CharacterFrame.shown, true, "character sheet open")
    env.G.CharacterFrame:Hide()
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown after closing it")
end)

Test("B opens the bag on its own and closes it again", function()
    local env = Load()
    local bags = env.G.ContainerFrameCombinedBags
    env.G.ToggleBackpack()
    env.Tick()
    Eq(bags.shown, true, "bag open")
    Eq(env.OnStage("ContainerFrameCombinedBags"), true, "bag on the stage")
    Eq(env.UIParent.shown, false, "UI shown")
    env.G.ToggleBackpack()
    env.Tick()
    Eq(bags.shown, false, "bag open after the second press")
    Eq(env.calls[#env.calls], "CloseAllBags", "last bag call")
    Eq(env.UIParent.shown, false, "UI shown")
end)

Test("chat sits on the stage, faded out unless typing", function()
    local env = Load()
    local box = env.G.ChatFrame1EditBox
    Eq(env.OnStage("ChatFrame1EditBox"), true, "edit box on the stage")
    Eq(box.alpha, 0, "edit box alpha")
    box.focus = true
    box:Run("OnEditFocusGained")
    env.Tick()
    Eq(box.alpha, 1, "alpha while typing")
    box.focus = false
    box:Run("OnEditFocusLost")
    env.Tick(1)
    Eq(box.alpha, 1, "alpha just after typing")
    env.Tick(5)
    Eq(box.alpha, 0, "alpha after the linger")
end)

Test("tooltips, quest text and the breath bar stay visible", function()
    local env = Load()
    Eq(env.OnStage("GameTooltip"), true, "tooltip on the stage")
    Eq(env.OnStage("UIErrorsFrame"), true, "quest text on the stage")
    Eq(env.OnStage("MirrorTimerContainer"), true, "breath bar container on the stage")
    Eq(env.G.MirrorTimer1.parent, env.G.MirrorTimerContainer, "breath bar parent")
    Eq(env.G.UIErrorsFrame.alpha, 1, "quest text alpha")
    env.Fire("PLAYER_REGEN_DISABLED")
    Eq(env.G.GameTooltip.parent, env.UIParent, "tooltip parent in combat")
end)

Test("tooltips keep their strata on the stage and back", function()
    local env = Load()
    Eq(env.G.GameTooltip.strata, "TOOLTIP", "strata on the stage")
    env.Fire("PLAYER_REGEN_DISABLED")
    Eq(env.G.GameTooltip.parent, env.UIParent, "tooltip parent in combat")
    Eq(env.G.GameTooltip.strata, "TOOLTIP", "strata back on UIParent")
end)

Test("a bag on the stage stays under its own buttons", function()
    local env = Load()
    local bags = env.G.ContainerFrameCombinedBags
    bags.level = 10
    local sort = env.NewFrame("BagItemAutoSortButton", bags, true)
    sort.level = 11
    env.G.ToggleBackpack()
    env.Tick()
    Eq(env.OnStage("ContainerFrameCombinedBags"), true, "bag on the stage")
    Eq(sort.level > bags.level, true, "sort button above the bag")
    Eq(sort.strata, bags.strata, "sort button strata")
    env.G.ToggleBackpack()
    env.Tick()
    Eq(bags.parent, env.UIParent, "bag parent after closing")
    Eq(sort.strata, bags.strata, "sort button strata after closing")
end)

Test("Esc closes a bag shown on its own and keeps the UI hidden", function()
    local env = Load()
    local bags = env.G.ContainerFrameCombinedBags
    env.G.ToggleBackpack()
    env.Tick()
    Eq(bags.shown, true, "bag open")
    env.UIParent:Show() -- Blizzard's Esc
    env.Tick()
    Eq(bags.shown, false, "bag open after Esc")
    Eq(env.UIParent.shown, false, "UI shown after Esc")
    env.UIParent:Show() -- Esc again, nothing open: the UI comes back
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown after the second Esc")
end)

-- A minimap button: a child of the minimap, which sits on the stage.
local function Click(env, fn)
    env.mouse = env.NewFrame("LibDBIcon10_Addon", env.G.Minimap, true)
    env.Fire("GLOBAL_MOUSE_DOWN", "LeftButton")
    fn()
    env.Fire("GLOBAL_MOUSE_UP", "LeftButton")
    env.Tick()
end

Test("a minimap button's window shows on its own; Esc closes it", function()
    local env = Load()
    local window = env.NewFrame("SomeAddonConfig", env.UIParent, false)
    Click(env, function() window:Show() end)
    Eq(env.UIParent.shown, false, "UI shown")
    Eq(env.OnStage("SomeAddonConfig"), true, "window on the stage")
    env.Tick(0.3)
    Eq(env.OnStage("SomeAddonConfig"), true, "window on the stage after the click")
    env.UIParent:Show() -- Esc
    env.Tick()
    Eq(window.shown, false, "window open after Esc")
    Eq(window.parent, env.UIParent, "window parent after Esc")
    Eq(env.UIParent.shown, false, "UI shown after Esc")
end)

Test("a panel opened from the minimap shows on its own too", function()
    local env = Load()
    local journal = env.NewFrame("EncounterJournal", env.UIParent, false)
    Click(env, function() env.G.ShowUIPanel(journal) end)
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown")
    Eq(env.OnStage("EncounterJournal"), true, "journal on the stage")
    journal:Hide()
    env.Tick(0.3)
    -- Opened later some other way, it brings the UI back as before.
    env.mouse = nil
    env.G.ShowUIPanel(journal)
    env.Tick()
    env.Tick()
    Eq(env.UIParent.shown, true, "UI shown when opened without a click")
end)

Test("a closed minimap window showing itself later leaves the UI hidden", function()
    local env = Load()
    local window = env.NewFrame("SomeAddonConfig", env.UIParent, false)
    Click(env, function() window:Show() end)
    env.Tick(0.3)
    window:Hide()
    env.Tick()
    Eq(window.parent, env.UIParent, "window parent after closing")
    env.mouse = nil
    window:Show() -- the addon, on its own
    env.Tick()
    env.Tick()
    Eq(env.UIParent.shown, false, "UI shown")
    for _, call in ipairs(env.calls) do
        Eq(call:find("ShowUIPanel") == nil, true, "no ShowUIPanel on an addon frame")
    end
    env.Slash("DUISTATUS")
end)

Test("a minimap click skips forbidden frames", function()
    local env = Load()
    local forbidden = env.NewFrame(nil, env.UIParent, true)
    function forbidden:IsForbidden() return true end
    function forbidden:IsShown() error("calling 'IsShown' on bad self") end
    local window = env.NewFrame("SomeAddonConfig", env.UIParent, false)
    Click(env, function() window:Show() end)
    Eq(env.OnStage("SomeAddonConfig"), true, "window on the stage")
end)

Test("a click in the world doesn't make windows show on their own", function()
    local env = Load()
    local window = env.NewFrame("SomeAddonConfig", env.UIParent, false)
    env.mouse = nil
    env.Fire("GLOBAL_MOUSE_DOWN", "LeftButton")
    window:Show()
    env.Fire("GLOBAL_MOUSE_UP", "LeftButton")
    env.Tick()
    Eq(env.OnStage("SomeAddonConfig"), false, "window on the stage")
end)

Test("the minimap stays visible, unless /dui-minimap off", function()
    local env = Load()
    Eq(env.OnStage("MinimapCluster"), true, "minimap cluster on the stage")
    Eq(env.G.Minimap.parent, env.G.MinimapCluster, "minimap parent")
    env.Slash("DUIMINIMAP", "off")
    Eq(env.G.MinimapCluster.parent, env.UIParent, "cluster parent with the option off")
    env.Slash("DUIMINIMAP", "on")
    Eq(env.OnStage("MinimapCluster"), true, "cluster on the stage again")
end)

Test("/dui-status runs", function()
    local env = Load()
    env.Slash("DUISTATUS")
    Eq(type(env.G.DynamicImmersiveUIDB.lastStatus), "table", "saved status")
end)

print(("%d passed, %d failed"):format(passed, failed))
if failed > 0 then os.exit(1) end
