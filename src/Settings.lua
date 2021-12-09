FavoriteItemsMarker = FavoriteItemsMarker or {}
local FIM = FavoriteItemsMarker

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
            type = "editbox",
            name = "Favorite item names",
            tooltip = "Enter full or partial strings, separated by %. If an item name contains the full or partial string, an indicator will be displayed",
            default = "",
            getFunc = function()
                return table.concat(FIM.savedOptions.partialNames, "%")
            end,
            setFunc = function(value)
                FIM.savedOptions.partialNames = {}
                for str in string.gmatch(value, "([^%%]+)") do
                    str = string.gsub(str, "^%s+", "")
                    str = string.gsub(str, "%s+$", "")
                    table.insert(FIM.savedOptions.partialNames, str)
                end
            end,
            isExtraWide = true,
            isMultiline = true,
            width = "full",
        },
    }

    FIM.addonPanel = LAM:RegisterAddonPanel("FavoriteItemsMarkerOptions", panelData)
    LAM:RegisterOptionControls("FavoriteItemsMarkerOptions", optionsData)
end
