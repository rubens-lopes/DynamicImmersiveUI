-- A notice at login: this addon is no longer actively maintained, and
-- Forever Immersion is recommended instead. Shown until closed with "Got it";
-- the X only closes it for this session.
--
-- Our own frame, parented to nothing, so it shows with the UI hidden. No
-- StaticPopup: its dialog table is Blizzard's, and writing to it from an
-- addon is a taint risk this addon doesn't need.

local TITLE = "Dynamic Immersive UI"
local URL = "https://www.curseforge.com/wow/addons/forever-immersion"
local TEXT = TITLE .. " is no longer actively maintained. Thank you all for using it!\n\n"
    .. "Last fixes:\n"
    .. "- The minimap stays visible with SexyMap.\n"
    .. "- Chat no longer closes while you're typing when a fight ends.\n"
    .. "- Using items from your bags is no longer blocked after visiting the bank.\n\n"
    .. "For the same kind of immersion, try Forever Immersion on CurseForge:"

local notice

local function Build()
    local f = CreateFrame("Frame", "DynamicImmersiveUINotice", nil, "BackdropTemplate")
    f:SetScale(UIParent:GetScale())
    f:SetFrameStrata("DIALOG")
    f:SetWidth(460)
    f:SetPoint("TOP", 0, -180)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText(TITLE)

    local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 24, -48)
    text:SetPoint("TOPRIGHT", -24, -48)
    text:SetJustifyH("LEFT")
    text:SetText(TEXT)
    -- Title, text, address, hint and button.
    f:SetHeight(48 + text:GetStringHeight() + 12 + 20 + 20 + 50)

    -- The game can't open links: the address is selected, ready for Ctrl+C.
    local url = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    url:SetSize(340, 20)
    url:SetPoint("TOP", text, "BOTTOM", 0, -12)
    url:SetAutoFocus(false)
    url:SetText(URL)
    url:SetCursorPosition(0)
    url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    url:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(URL)
            self:HighlightText()
        end
    end)
    url:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    url:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local hint = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOP", url, "BOTTOM", 0, -4)
    hint:SetText("Click the address, then Ctrl+C to copy it.")

    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(110, 22)
    ok:SetPoint("BOTTOM", 0, 18)
    ok:SetText("Got it")
    ok:SetScript("OnClick", function()
        DynamicImmersiveUIDB = DynamicImmersiveUIDB or {}
        DynamicImmersiveUIDB.noticeSeen = true
        f:Hide()
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    return f
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    if DynamicImmersiveUIDB and DynamicImmersiveUIDB.noticeSeen then return end
    -- After the loading screen.
    C_Timer.After(3, function()
        notice = notice or Build()
        notice:Show()
    end)
end)

-- /dui-notice shows it again.
SLASH_DUINOTICE1 = "/dui-notice"
SlashCmdList.DUINOTICE = function()
    notice = notice or Build()
    notice:Show()
end
