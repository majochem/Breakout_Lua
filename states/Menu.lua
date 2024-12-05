require "globals"
local love = require "love"
local Page = require "components.Page"

Menu = function (game, player)

    local menu_pages = {
        main = "main",
        settings = "settings",
        load_save = "load_save",
        leaderboard = "leaderboard",
    }

    -- SOUND
    local effect = {
        highlight = SOUND.sound_groups.menu.effects.hover,
        activate = SOUND.sound_groups.menu.effects.activate
    }

    local active_page = "main" -- initially active page is main
    local f_in_progress = function ()
        return game.in_progress
    end
    
    -- Main menu
    local main = {
        -- defining properties
        title = "Main Menu",
        page_id = "main",
        x = 0,
        y = 0,
        height = SCR_HEIGHT,
        width = SCR_SCALE_WIDTH,
        active = true, -- only main menu starts out as initially active

        has_header = true,
        has_tabs = false,
        has_columns = true,
        has_footer = false,

        

        menu_entries = {
        -- defining individual menu entries
            resume = {
                text = "Resume Game",
                index = 1,
                visible = f_in_progress(), -- only visible when game is in progress

                func = function ()
                    game:startGame()
                    game:changeGameState("paused")
                end

            },

            new_game = {
                text = "New Game",
                index = 2,
                visible = true,
                func = function ()
                    game.in_progress = false -- todo get confirmation to reset game
                    game:startGame()
                end,

            },

            load_save = {
                text = "Load Save",
                index = 3,
                visible = true,
            },


            settings = {
                text = "Settings",
                index = 4,
                visible = true,
                func = function ()
                    game.menu:changeMenuPage("settings")
                end,
                func_arg = nil
            },
            leaderboard = {
                text = "Leaderboard",
                index = 5,
                visible = true,
            },
            quit = {
                text = "Quit",
                index = 6,
                visible = true,
                func = function() game:quitGame() end,
            }
        }
    }

    -- Submenu 1: Settings
    local settings = {
        title = "Settings",
        page_id = "settings",
        x = 0,
        y = 0,
        height = SCR_HEIGHT,
        width = SCR_SCALE_WIDTH,
        active = true, -- TODO only main menu starts out as initially active. change later

        

        has_header = true,
        has_tabs = true,
        has_columns = true,
        has_footer = true,


        --TODO: the settings menu should be automatically populated, base on a saved json file
        --tabs
        -- each setting category should have its own tab
        tab_list = {
            "general",
            "video",
            "audio",
            "controls"
        },

        
        --columns
        -- each tab should have two columns, one for the value to be changed, and one for the current value
         
        column_list = {
            left = {
                general = {"difficulty", "test1", "test2"},
                video = {"window mode", "resolution", "style theme"},
                audio = {"music volume", "effect volume", "background track"},
                controls = {"left", "right", "pause", "confirm"}
            },

            -- TODO: this would have to be arrays, not strings for changeable values
            center = {
                general = {"easy", "test1", "test2"},
                video = {"windowed", SCR_SCALE_WIDTH .. " x " .. SCR_DEFAULT_HEIGHT, "default"},
                audio = {"100%", "100%", "default"},
                controls = {"left", "right", "escape", "enter"}

            }
        

        },

        -- footer
        footer = {
            entries = {
                back = {
                    text = "Back",
                    index = 1,
                    visible = true,
                    func = function ()
                        game.menu:changeMenuPage("main")
                    end,
                    func_arg = nil
                },

                save = {
                    text = "Save Changes",
                    index = 2,
                    visible = true,
                    func = nil,
                    func_arg = nil
                }
            }
        }
    
    }
    return {
        menu_pages = menu_pages,
        -- the following are the menu page objects
        main = main,
        
        settings = settings,
        
        active_page = active_page,

        initMain = function (self)

            -- initialize main page object
            local main_page = Page(self.x, self.y, self.width, self.height, self.active)

            main_page._page_id = self.main.page_id -- this is just for better tracking during debugging

            -- set up Header
            main_page:initHeader(self.main.title)

            -- set up Tabs
            main_page.tabs.entries = {}
            main_page:initTabs(main_page.tabs)

            -- set up Columns
                -- main menu only has one column, which is accessible

                -- left
                main_page.columns.left.entries = main.menu_entries
                main_page.columns.left.accessible = true

                --center
                main_page.columns.center = {}
                --main_page.columns.center.accessible = false
                
                -- right
                main_page.columns.right = {}
                --main_page.columns.right.accessible = false

            main_page:initColumns(main_page.columns)

            -- set up Footer
            main_page.footer.entries = {} -- No Footer? (maybe show version number or date/time later?)
            main_page:initFooter(main_page.footer)
            
            -- generate navigation matrix
            main_page:generateNavMatrix()


            self.main.page = main_page

        end,

        initSettings = function (self)

            -- initialize settings page object
            local settings_page = Page(self.x, self.y, self.width, self.height, self.active)

            settings_page._page_id = self.settings.page_id -- this is just for better tracking during debugging

            -- set up Header
            settings_page:initHeader(self.settings.title)

            -- set up Tabs
            settings_page.tabs.entries = self.generateTabs(self.settings.tab_list)
            settings_page:initTabs(settings_page.tabs)

            -- set up Columns
                -- settings menu only has two columns, both accessible
                --TODO: currently only being set up for "general"
                -- left
                settings_page.columns.left.entries = self.generateColumns(self.settings.column_list.left.general, "left")
                settings_page.columns.left.accessible = true

                --center
                settings_page.columns.center.entries = self.generateColumns(self.settings.column_list.center.general, "center")
                settings_page.columns.center.accessible = true
                
                -- right
                settings_page.columns.right = {}
                --settings_page.columns.right.accessible = false

            settings_page:initColumns(settings_page.columns)

            -- set up Footer
            settings_page.footer.entries = settings.footer.entries -- No Footer? (maybe show version number or date/time later?)
            settings_page:initFooter(settings_page.footer)
            
            -- generate navigation matrix
            settings_page:generateNavMatrix()


            self.settings.page = settings_page

        end,

        init = function(self)
            self:initMain()
            self:initSettings()
            game.menu = self
        end,

        draw = function (self)
            
            self[self.active_page].page:draw()
        end,

    
        navigateMouse = function (self)
            local mouse_x, mouse_y = love.mouse.getPosition()
            local active_page_key = menu_pages[self.active_page] -- provides key of active page as a string
            
            local current_page = self[active_page_key].page


            -- this loop iterates through the matrix column by column
            -- each column contains an array, which in turn contains button objects at the y_index corresponding to the x_index
            for x_index, x_column in pairs(current_page.nav_matrix) do

                for y_index, y_row in pairs(current_page.nav_matrix[x_index]) do
                    local entry = y_row -- entry is the object at the current x,y index of the nav_matrix
                    
                    if not (entry.x and entry.y and entry.width and entry.height) then
                        print("Error: A nav_matrix element is nil at: " .. x_index .. ", " .. y_index)
                    end

                    if entry.visible == nil then entry.visible = true end -- assume visible as default

                    if entry.visible then
                        if mouse_x >= entry.x and mouse_x <= (entry.x + entry.width) then
                            if mouse_y >= entry.y and mouse_y <= (entry.y + entry.height) then
                                if not current_page.nav_matrix[x_index][y_index].active then
                                current_page.nav_matrix[x_index][y_index].active = true
                                SOUND:playEffect(effect.highlight)
                                end
                                -- if mouse is clicked, while active, activate (duh)
                                if love.mouse.isDown(1) then 
                                    SOUND:playEffect(effect.activate)
                                    current_page.nav_matrix[x_index][y_index]:activate() 
                                end

                            else
                                current_page.nav_matrix[x_index][y_index].active = false
                            end
                        else
                            current_page.nav_matrix[x_index][y_index].active = false
                        end
                    end
                end

            end
            
        end,

        changeMenuPage = function (self, page_id)

            page_id = page_id or "main" -- to catch 'nil' values

            -- this loop isn't really necessary, but is here to catch misspelled or wrong arguments
            for _, page in pairs(self.menu_pages) do
                if page_id == page then
                    self.active_page = self[page].page_id
                    self[page].active = true
                    
                else
                    if self[page] then
                        self[page].active = false
                    end
                end
            end
            
        end,

        -- TODO: make the "generate" function provide more advanced properties, such as functions, visibility, style behavior etc.
        generateTabs = function (tab_list)
        -- generates basic attributes for tabs best on an array of strings.


            local tab_entries = {}

            if tab_list == {} or tab_list == nil then
                return tab_entries -- if no string array is provdided, return empty string
            end

            for i, value in pairs(tab_list) do
                value = string.lower(value) -- keys should be lower case

                if tab_entries[value] == nil then tab_entries[value] = {} end -- initialize the array if it doesn't exist yet
                

                tab_entries[value]["text"] = StringToTitleCase(value)
                tab_entries[value]["index"] = i
            end
            
            return tab_entries

        end,

        generateColumns = function (column_list, position)
            -- generates basic attributes for columns best on an array of strings.

                position = position or "left" -- if no position is given, assume left
                local column_entries = {}

                if column_list == {} or column_list == nil then
                    return column_entries -- if no string array is provdided, return empty string
                end
    
                for i, value in pairs(column_list) do
                    value = string.lower(value) -- keys should be lower case

                    if column_entries[value] == nil then column_entries[value] = {} end -- initialize the array if it doesn't exist yet
    
    
                    column_entries[value]["text"] = StringToTitleCase(value)
                    column_entries[value]["index"] = i
                end
                
                return column_entries
    
        end,

        generateFooter = function (footer_list)
        -- generates basic attributes for footers based on an array of strings.
        -- todo currently only works for non-actionable footer buttons


            local footer_entries = {}

            if footer_list == {} or footer_list == nil then
                return footer_entries -- if no string array is provdided, return empty string
            end

            for i, value in pairs(footer_list) do
                value = string.lower(value) -- keys should be lower case

                if footer_entries[value] == nil then footer_entries[value] = {} end -- initialize the array if it doesn't exist yet

                footer_entries[value]["text"] = StringToTitleCase(value)
                footer_entries[value]["index"] = i
            end
            
            return footer_entries

        end,

        -- this function returns if a relevant menu key is down
        getMenuKeyisdown = function ()
            local relevant_key = false
            local pressed_key = ""

        -- the current implementation will technically only take the first if multiple keys are pressed, but that's an edge case I'm willing to accept

            for _, key_value in pairs(CONTROLS.menu) do
                if love.keyboard.isDown(key_value) then
                    pressed_key = key_value
                    relevant_key = true
                    goto continue
                end
            end
            ::continue::

            return relevant_key, pressed_key
        end,

        navigateKeyboard = function (self, _key)
            local active_page_key = menu_pages[self.active_page]


            local controls = {
                up = CONTROLS.menu.navigate_up,
                down = CONTROLS.menu.navigate_down,
                right = CONTROLS.menu.navigate_right,
                left = CONTROLS.menu.navigate_left,
                back = CONTROLS.menu.back,
                confirm = CONTROLS.menu.confirm
            }

            local direction = {
                up = {
                    dx = 0,
                    dy = -1
                },

                down = {
                    dx = 0,
                    dy = 1
                },

                right = {
                    dx = 1,
                    dy = 0
                },

                left = {
                    dx = -1,
                    dy = 0
                }
            }

            local nav_action = {} -- contains the functions for the respective keys
            nav_action[controls.up] = function ()
                self[active_page_key].page:navigateNavMatrix(direction.up.dx, direction.up.dy)
                end
            nav_action[controls.down] = function ()
                self[active_page_key].page:navigateNavMatrix(direction.down.dx, direction.down.dy)
            end

            nav_action[controls.left] = function ()
                self[active_page_key].page:navigateNavMatrix(direction.left.dx, direction.left.dy)
            end

            nav_action[controls.right] = function ()
                self[active_page_key].page:navigateNavMatrix(direction.right.dx, direction.right.dy)
            end

            nav_action[controls.confirm] = function ()
                local active_index = self[active_page_key].page.nav_values.active
                self[active_page_key].page.nav_matrix[active_index.x][active_index.y]:activate()
                SOUND:playEffect(effect.activate)
            end

            nav_action[controls.back] = function ()
                if self.active_page == menu_pages.main then
                    -- if we're in the main menu, back is quit
                    game:quitGame()
                else
                    -- otherwise return to main menu
                    self:changeMenuPage(menu_pages.main)
                end
            end

            if nav_action[_key] == nil then
                -- do nothing
            else
                nav_action[_key]()
            end


            
        end
    
        

    }
    


end

return Menu