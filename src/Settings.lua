FavoriteItemsMarker = FavoriteItemsMarker or {}
local FIM = FavoriteItemsMarker

local function RemoveItem(value)
    -- Index
    for i, name in ipairs(FIM.savedOptions.partialNames) do
        if (value == name) then
            table.remove(FIM.savedOptions.partialNames, i)
            return
        end
    end
end

local function OnSettingsChanged()
    ZO_ScrollList_RefreshVisible(ZO_PlayerInventoryList)
    ZO_ScrollList_RefreshVisible(ZO_PlayerBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_GuildBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_HouseBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelImprovementPanelInventoryBackpack)
    ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack)
    ZO_ScrollList_RefreshVisible(ZO_StoreWindowList)
end

function FIM.CreateSettingsMenu()
    local LAM = LibAddonMenu2
    local panelData = {
        type = "panel",
        name = FIM.name,
        displayName = "|c3bdb5eFavorite Items Marker|r",
        author = "Kyzeragon",
        version = FIM.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local optionsData = {
        {
            type = "description",
            text = "If an item name contains the full or partial string (case-insensitive), a |c00FF00|t22:22:/esoui/art/icons/pet_voriplasm.dds:inheritcolor|t|r will be displayed next to the item texture. Probably won't play super well with GridList but I'm too lazy to make more granular settings.",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Enabled",
            tooltip = "Enables the indicator",
            default = true,
            getFunc = function() return FIM.savedOptions.enabled end,
            setFunc = function(value)
                FIM.savedOptions.enabled = value
                OnSettingsChanged()
            end,
            width = "full",
        },
        {
            type = "dropdown",
            name = "Item names filter",
            tooltip = "Full or partial item names. Select one from this dropdown to remove it",
            choices = {},
            getFunc = function()
                FIM_PartialNames:UpdateChoices(FIM.savedOptions.partialNames)
            end,
            setFunc = function(value)
                RemoveItem(value)
                CHAT_SYSTEM:AddMessage(string.format("Removed \"%s\" from indicator filter.", value))
                FIM_PartialNames:UpdateChoices(FIM.savedOptions.partialNames)
                OnSettingsChanged()
            end,
            width = "full",
            reference = "FIM_PartialNames",
            disabled = function() return not FIM.savedOptions.enabled end,
        },
        {
            type = "editbox",
            name = "Add item name",
            tooltip = "Enter an item name to add it to the filter list",
            getFunc = function()
                return ""
            end,
            setFunc = function(value)
                if (string.match(value, "^%s*$") or string.match(value, "%%")) then
                    CHAT_SYSTEM:AddMessage(string.format("Error: \"%s\" is empty or contains %% characters.", value))
                    return
                end
                table.insert(FIM.savedOptions.partialNames, value)
                CHAT_SYSTEM:AddMessage(string.format("Added \"%s\" to indicator filter.", value))
                OnSettingsChanged()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return not FIM.savedOptions.enabled end,
        },
        {
            type = "submenu",
            name = "Advanced",
            controls = {
                {
                    type = "description",
                    text = "This is the same as the above options but allows you to import, export, or edit multiple at once.",
                    width = "full",
                },
                {
                    type = "editbox",
                    name = "Favorite item names",
                    tooltip = "Enter full or partial strings, separated by %",
                    getFunc = function()
                        return table.concat(FIM.savedOptions.partialNames, "%")
                    end,
                    setFunc = function(value)
                        FIM.savedOptions.partialNames = {}
                        for str in string.gmatch(value, "([^%%]+)") do
                            str = string.gsub(str, "^\n+", "")
                            str = string.gsub(str, "\n+$", "")
                            str = string.gsub(str, "\n+", " ")
                            if (str ~= "") then
                                table.insert(FIM.savedOptions.partialNames, str)
                            end
                        end
                        FIM_PartialNamesEdit:UpdateValue()
                        OnSettingsChanged()
                    end,
                    isExtraWide = true,
                    isMultiline = true,
                    width = "full",
                    disabled = function() return not FIM.savedOptions.enabled end,
                    reference = "FIM_PartialNamesEdit",
                },
            },
        },
    }

    FIM.addonPanel = LAM:RegisterAddonPanel("FavoriteItemsMarkerOptions", panelData)
    LAM:RegisterOptionControls("FavoriteItemsMarkerOptions", optionsData)
end
