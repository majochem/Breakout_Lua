local love = require "love"
local SFX = require "components.SFX"

local lunajson = require "lunajson"

Settings = function ()
    -- GRAPHIC STYLES
    local style_file = love.filesystem.read("src/settings/style.json")
    local theme_data
    local theme = "default"

    -- list of currently supported object types
    -- NOTE: any new bject types need to be added here and not just to the JSON
    local object_types = {
        header = "header",
        tab = "tab",
        tab_entry = "tab_entry",
        column = "column",
        column_entry = "column_entry",
        column_entry_main = "column_entry_main", -- this is specifically for cases with only one column
        button = "button",
        text_box = "text_box",
        stat_display = "stat_display",
        screen_msg = "screen_msg",
        screen_sub_msg = "screen_sub_msg",
        player = "player", -- the actual player paddle
        play_area = "play_area", -- playable area
        brick = "brick" -- individual brick
    
    } 
    

    if not style_file then
        print("Error: Style file not found")
    else
        theme_data = lunajson.decode(style_file)
    end

    --AUDIO
    local sound = SFX()

    
    return {
        theme = theme,
        theme_data = theme_data,
        object_types = object_types,
        sound = sound,

        getStylePropertyTbl = function (self, object_type)
        -- fetches the visual properties for a given oject type like "button", "header", etc

            -- redeclaring local theme variables in case the object properties were changed
            local theme = self.theme
            local theme_data = self.theme_data
            local result = {}

            -- Check if the object type exists in the theme
            if theme_data.themes[theme] and theme_data.themes[theme][object_type] then
                -- Merge the theme properties into the result
                for key, value in pairs(theme_data.themes[theme][object_type]) do
                    result[key] = value
                end
            end
            
            -- Merge the default properties for the object
            if theme_data.default[object_type] then
                for key, value in pairs(theme_data.default[object_type]) do
                    -- Only add to result if it hasn't been set yet (from the theme)
                    if result[key] == nil then
                        result[key] = value
                    end
                end
            end

            -- merge default properties that are no object-specific
            for key, value in pairs(theme_data.default) do
                -- check if the current element contains actual values or sub-values for object types
                -- note: cannot use "TableContainsValue" function here because settings is loaded before globals
                -- so have to rewrite mini function here
                local is_object_type = false

                for _, obj_value in pairs(object_types) do
                    if key == obj_value then
                        is_object_type = true
                        break -- no need to continue loop if element is found
                    end
                end


                -- if it's a property, check if it's already contained in the result
                if not is_object_type then
                    -- if not assigned yet, assign default value
                    if result[key] == nil then
                        result[key] = value
                    end
                end
            end

            return result


        end,

        initializeStyle = function (self)
        -- does the inital loading of all visal properties for all object types
        -- returns all object types inside a table with their visual properties


            local result = {}
            local object = {}

            -- iterate over possible object types, get their properties and write them to the result table/dictionray
            for key, object_type in pairs(object_types) do
                object = self:getStylePropertyTbl(object_type)

                -- write object specific properties to result
                result[key] = object

            end


            return result


            
        end,

        setTheme = function (self, new_theme)
        -- changes the theme. only accepts values contained in "valid_themes"
            local valid_themes = {
                "default",
                "light",
                "dark"
            }

            local valid_entry = false

            -- go through all valid options. if it's one of those change it
            for _, theme_name in pairs(valid_themes) do
                if new_theme == theme_name then
                    valid_entry = true
                    self.theme = new_theme
                    --TODO: reload all theme properties? 
                    break
                    
                end
            end

            if not valid_entry then
                print("No valid theme entered. Theme was not changed")
            end

            
        end
    }
end

return Settings

