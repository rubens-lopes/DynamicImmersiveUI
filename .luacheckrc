std = "lua51"
max_line_length = false
exclude_files = { ".release" }
-- The test stubs are methods that ignore self.
files["tests/"] = { self = false }

globals = {
    "DynamicImmersiveUIDB",
    "SLASH_DUIARROW1",
    "SLASH_DUIHELP1",
    "SLASH_DUIHIDE1",
    "SLASH_DUIMINIMAP1",
    "SLASH_DUIMESSAGES1",
    "SLASH_DUIOPTIONS1",
    "SLASH_DUISOLO1",
    "SLASH_DUISTATUS1",
    "SLASH_DUITARGET1",
    "SlashCmdList",
}

read_globals = {
    "C_AddOns", "C_Timer",
    "CloseAllBags",
    "CloseLoot",
    "ContainerFrame_ClearFullScreenFrame",
    "ContainerFrame_SetFullScreenFrame",
    "CreateFrame",
    "FrameUtil",
    "GetMouseFocus",
    "GetMouseFoci",
    "GetTime",
    "HasNewMail",
    "HideUIPanel",
    "hooksecurefunc",
    "InCombatLockdown",
    "InterfaceOptions_AddCategory",
    "InterfaceOptionsFrame_OpenToCategory",
    "issecretvalue",
    "UnitGUID",
    "MinimapCluster",
    "NUM_CHAT_WINDOWS",
    "SetUIVisibility",
    "Settings",
    "ShowUIPanel",
    "UIParent",
    "UnitExists",
    "UnitIsDead",
    "WorldMapFrame",
}
