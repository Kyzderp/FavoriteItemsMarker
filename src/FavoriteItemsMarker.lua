FavoriteItemsMarker = FavoriteItemsMarker or {}
local FIM = FavoriteItemsMarker
FIM.name = "FavoriteItemsMarker"
FIM.version = "0.1.0"

local defaultOptions = {
    enabled = true,
    partialNames = {},
}

---------------------------------------------------------------------
-- Favorites or search or whatever
---------------------------------------------------------------------
local function ShouldShowIndicator(link)
    local lowerItemName = string.lower(GetItemLinkName(link))
    for _, partialName in ipairs(FIM.savedOptions.partialNames) do
        if (string.find(lowerItemName, string.lower(partialName))) then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------
-- Control indicator
-- Yoinked from LootLog with some modifications
---------------------------------------------------------------------
local CONTEXT_MAIL_ATTACHMENT = "MAIL"

local function FlagListItem(link, control, context)
    if (context ~= CONTEXT_MAIL_ATTACHMENT) then
        -- We're only interested in the icon button subcontrol, not the inventory slot control
        -- /esoui/ingame/inventory/inventoryslot.xml
        control = control:GetNamedChild("Button")
    end
    if (not control) then return end

    -- Different systems have different ways of passing the item link
    local itemLink
    if (type(link) == "string") then
        -- Trade slots
        itemLink = link
    elseif (type(link) == "table") then
        -- Vendors and loot windows
        itemLink = link[1](context[link[2]])
    else
        -- Bags/banks
        itemLink = GetItemLink(context.bagId, context.slotIndex)
    end

    local shouldShow = FIM.savedOptions.enabled and ShouldShowIndicator(itemLink)

    -- Get or create our indicator
    local indicator = control:GetNamedChild("FIMIndicator")
    if (not indicator) then
        -- Be lazy; don't create an indicator unless we actually need to show it
        if (not shouldShow) then return end

        -- Create and initialize the indicator
        indicator = WINDOW_MANAGER:CreateControl(control:GetName() .. "FIMIndicator", control, CT_TEXTURE)
        indicator:SetDimensions(22, 22)
        indicator:SetInheritScale(false)
        indicator:SetAnchor(LEFT, control, RIGHT)
        indicator:SetDrawTier(DT_HIGH)
    end

    if (shouldShow) then
        indicator:SetTexture("/esoui/art/icons/pet_voriplasm.dds")
        indicator:SetColor(0, 1, 0)
        indicator:SetHidden(false)
    else
        indicator:SetHidden(true)
    end
end

---------------------------------------------------------------------
-- UI hook
-- Yoinked from LootLog with some modifications
---------------------------------------------------------------------
local function HookLists()
    local ProcessListHooks = function(lists)
        for _, list in ipairs(lists) do
            local scrollList = _G[list.name]
            if (scrollList and ZO_ScrollList_GetDataTypeTable(scrollList, 1)) then
                SecurePostHook(ZO_ScrollList_GetDataTypeTable(scrollList, 1), "setupCallback", function(...) FlagListItem(list.link, ...) end)
            end
        end
    end

    -- Hook regular item lists
    ProcessListHooks({
        { name = "ZO_PlayerInventoryList" },
        { name = "ZO_PlayerBankBackpack" },
        { name = "ZO_GuildBankBackpack" },
        { name = "ZO_HouseBankBackpack" },
        { name = "ZO_SmithingTopLevelImprovementPanelInventoryBackpack" },
        { name = "ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack" },
        { name = "ZO_StoreWindowList", link = { GetStoreItemLink, "slotIndex" }},
        { name = "ZO_BuyBackList", link = { GetBuybackItemLink, "slotIndex" }},
        { name = "ZO_LootAlphaContainerList", link = { GetLootItemLink, "lootId" }},
    })

    -- The guild store can't be hooked until it has been opened at least once
    EVENT_MANAGER:RegisterForEvent(FIM.name, EVENT_OPEN_TRADING_HOUSE, function( eventCode )
        EVENT_MANAGER:UnregisterForEvent(FIM.name, EVENT_OPEN_TRADING_HOUSE)
        ProcessListHooks({
            { name = "ZO_TradingHouseBrowseItemsRightPaneSearchResults", link = { GetTradingHouseSearchResultItemLink, "slotIndex" }},
        })
    end)

    -- Trade window slots are not technically item lists, but they reuse the same inventory slot control
    -- /esoui/ingame/tradewindow/keyboard/tradewindow_keyboard.lua
    SecurePostHook(TRADE, "InitializeSlot", function( self, who, index, ... )
        FlagListItem(GetTradeItemLink(who, index), self.Columns[who][index].Control, { who = who, tradeIndex = index })
    end)

    SecurePostHook(TRADE, "ResetSlot", function( self, who, index )
        FlagListItem("", self.Columns[who][index].Control)
    end)

    -- Mail attachment slots are not technically item lists, but they reuse the same inventory slot control
    -- /esoui/ingame/mail/keyboard/mail*_keyboard.lua
    SecurePostHook(MAIL_INBOX, "RefreshAttachmentSlots", function( self )
        local numAttachments = self:GetMailData(self.mailId).numAttachments
        for i = 1, numAttachments do
            FlagListItem(GetAttachedItemLink(self.mailId, i), self.attachmentSlots[i], CONTEXT_MAIL_ATTACHMENT)
        end
    end)

    SecurePostHook(MAIL_SEND, "OnMailAttachmentAdded", function( self, attachSlot )
        FlagListItem(GetMailQueuedAttachmentLink(attachSlot), self.attachmentSlots[attachSlot], CONTEXT_MAIL_ATTACHMENT)
    end)

    SecurePostHook(MAIL_SEND, "OnMailAttachmentRemoved", function( self, attachSlot )
        FlagListItem("", self.attachmentSlots[attachSlot], CONTEXT_MAIL_ATTACHMENT)
    end)
end

---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
-- Post-char load
local function OnPlayerActivated(_, initial)
    EVENT_MANAGER:UnregisterForEvent(FIM.name .. "PlayerActivated", EVENT_PLAYER_ACTIVATED)

    HookLists()
end

-- Pre-char load
local function Initialize()
    FIM.savedOptions = ZO_SavedVars:NewAccountWide("FavoriteItemsMarkerSavedVariables", 1, "Options", defaultOptions)

    FIM.CreateSettingsMenu()

    EVENT_MANAGER:RegisterForEvent(FIM.name .. "PlayerActivated", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

-- Register
local function OnAddOnLoaded(_, addonName)
    if (addonName == FIM.name) then
        EVENT_MANAGER:UnregisterForEvent(FIM.name, EVENT_ADD_ON_LOADED)
        Initialize()
    end
end
EVENT_MANAGER:RegisterForEvent(FIM.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
