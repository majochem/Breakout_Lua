require "globals"
local love = require "love"
local Button = require "components.Button"
local Text = require "components.Text"
local Font = require "components.Font"


-- Each page consists of a Header, Footer, Navigation Tabs and Columns of remainig content
-- Not all elements are always visible, but the visual arrangement remains the same by default
-- individual elements (tabs, column entries, footnotes) need to be populated via functions

Page = function (x, y, width, height, active)

    

    x = x or 0
    y = y or 0
    width = width or SCR_WIDTH
    height = height or SCR_HEIGHT
    active = active or false

    local margin_x = 20 * SCR_SCALE_WIDTH
    local margin_y = 20 * SCR_SCALE_HEIGHT
    local default_footer_height = 100 * SCR_SCALE_HEIGHT -- has to defined here because it's used for relative calculation within footer table
    local num_page_elements = 4 -- this is used to count # of necessary margins
    
    -- percentage margins in case of fallback adjustments
    local fallback_margin_y = 0.10
    local fallback_margin_x = 0.5




    -- HEADER
    -- definition of default header properties (might move to separate file later)
    local header = {
        type = "header",
        title = "No Title",
        

        x = margin_x,
        y = margin_y,
        width = SCR_WIDTH - (margin_x * 2),
        height = 100 * SCR_SCALE_HEIGHT,
        margin = 5 * SCR_SCALE_HEIGHT,
        accessible = false, -- whether area can be accessed by navigation by default


    }

    -- TABS (navigation tabs)
    -- definition of default tab properties (might move to separate file later)
    local tabs = {
        type = "tab",
        x = margin_x,
        y = header.height + header.y + margin_y,  -- positioned one margin below header
        width_total = SCR_WIDTH - (margin_x * 2),
        height_total = 50 * SCR_SCALE_HEIGHT,
        width_tab = 200 * SCR_SCALE_WIDTH,
        height_tab = 50 * SCR_SCALE_HEIGHT,
        visible = false,
        active = false,
        accessible = false, -- whether area can be accessed by navigation by default
        entries = {},

    }

    local footer = {
        type = "footer",
        x = margin_x,
        y = SCR_HEIGHT - default_footer_height - margin_y,  -- positioned one margin above screen bottom
        width_total = SCR_WIDTH - (margin_x * 2),
        height_total = default_footer_height,
        width_note = 200 * SCR_SCALE_WIDTH,
        height_note = 50 * SCR_SCALE_HEIGHT,
        gap = 10 * SCR_SCALE_WIDTH,
        visible = false,
        accessible = false, -- whether area can be accessed by navigation by default
        entries = {},
    }

    local columns ={
        type = "column",
        x = margin_x,
        y = tabs.y + tabs.height_total + margin_y, -- positioned one margin below tabs
        width_total = SCR_WIDTH - (margin_x * 2),
        active = false,
        visible = true,
        accessible = true, -- whether area can be accessed by navigation by default
        positions = {"left", "center", "right"},

        -- total height is relative to remaining space
        height_total = SCR_HEIGHT - (header.height + tabs.height_total + footer.height_total + (margin_y * (num_page_elements + 1))),
        height_row = 25 * SCR_SCALE_HEIGHT, --TODO: fetch this height from style settings based on font size?

        -- ratios are used to assign individual column widths. So far only three allowed layouts ( 1 to 3 columns)
        single_column_ratios = {1, 0, 0},
        dual_column_ratios = {0.3, 0.6, 0},
        triple_column_ratios = {0.2, 0.6, 0.2},

        -- gap between individual column entries
        margin_row = 15 * SCR_SCALE_HEIGHT,

        
        left = { 
            type = "column",
            position = "left",
            x = margin_x,
            y = tabs.y + tabs.height_total + margin_y, -- positioned one margin below tabs
            accessible = true, -- whether area can be accessed by navigation by default
            entries = {},
        },

        center = { 
            type = "column",
            position = "center",
            x = margin_x,
            y = tabs.y + tabs.height_total + margin_y, -- positioned one margin below tabs
            accessible = true, -- whether area can be accessed by navigation by default
            entries = {},
        },

        right = { 
            type = "column",
            position = "right",
            x = margin_x,
            y = tabs.y + tabs.height_total + margin_y, -- positioned one margin below tabs
            accessible = true, -- whether area can be accessed by navigation by default
            entries = {},
        },

    }
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        active = active,
        header = header,
        footer = footer,
        tabs = tabs,
        columns = columns,
        nav_matrix = {}, -- empty by default. this is the matrix for keyboard navigation and generated later

        -- This function is meant to ensure that row height isn't smaller than font size in pixels
        -- returns proper row height if given a height and object type (for style properties)
        getRowHeight = function (_height, _type)
            _type = _type or "default"
            local output_height = _height
            local font = STYLE[_type].font_size
            local font_px = Font().font_size_px[font]

            -- height should at least be font size in px + fallback margin above and below
            output_height = MathRound(math.max(_height, (font_px) + (font_px * fallback_margin_y * 2)),0)

            return output_height
        end,

        -- populates the actual buttons that need to be drawn on screen later
        -- requires a table of entries, typically the ".entries" property of a column, tab, footer, etc.
        -- assign button to individual entries
        -- return table with populated buttons
        populateButtons = function (self, entry_table)

        if entry_table == nil then
            return nil
        end
            
            -- for all entries in the entry table
            for key, value in pairs(entry_table.entries) do
                local entry = entry_table.entries[key]


                -- create Button object
                entry_table.entries[key].button = Button(entry.func, entry.func_arg, entry.x, entry.y, entry.text, entry.width, entry.height, nil, entry.type )
                entry_table.entries[key].button.active = entry_table.entries[key].active
                entry_table.entries[key].button.visible = entry_table.entries[key].visible

                
            end
            
            -- return table that has been populated with buttons
            return entry_table
        end,

        initHeader = function (self, text)
            self.header.text = text or self.header.title
            self.header.font_color = STYLE[self.header.type].font_color

            -- assign the header its one single button
            self.header.button = Button(nil, nil, self.header.x, self.header.y, self.header.text, self.header.width, self.header.height, self.header.margin, self.header.type)

        end,
        
        initTabs = function (self, tab_table)
        -- requires a tabs table that contains entries
        -- tabs should have a "text" and "index" (int) property
        
            -- check table exists
            if tab_table == nil then
                tab_table = {} -- not sure why I'm assigning this if I return after?
                print("Error: Tried to initialize empty tab list")
                return
            end
            
            local tab_entries = tab_table.entries

            -- if entries are nil, assume they're empty instead
            if tab_entries == nil then
                tab_entries = {}
                
            end

            -- make sure table indeces are correctly assigned
            tab_entries = SetTableIndex(tab_entries)

            
            local tab_n = GetTableN(tab_entries)

            -- if there is more than one tab entry it should be accessible by navigation
            if tab_n > 1 then
                self.tabs.accessible = true
            end

            -- if there are too many tabs, shrink down the width (not sure, if it will happen, but you never know)
            if (tab_n * self.tabs.width_tab) > self.tabs.width_total then

                -- if number is too large, divide total width by number of tabs
                self.tabs.width_tab = (self.tabs.width_total / tab_n)
                
            end

            -- go through provided tabs and assign text, coordiates and height values
---@diagnostic disable-next-line: param-type-mismatch
            for key, tab in pairs(tab_entries) do
                local current_tab ={}
                

                current_tab.x = self.tabs.x + (self.tabs.width_tab * (tab.index - 1))
                current_tab.y = self.tabs.y
                current_tab.width = self.tabs.width_tab
                current_tab.height = self.tabs.height_tab
                current_tab.text = tab.text or "No text assigned"
                current_tab.index = tab.index
                current_tab.type = SETTINGS.object_types["tab_entry"]

                -- initially always put the first tab as active
                if current_tab.index == 1 then
                    current_tab.active = true
                else
                    current_tab.active = false
                end

                -- add values to main tabs object
                self.tabs.entries[key] = current_tab

                self.tabs = self:populateButtons(self.tabs)

                

            end
            
        end,

        initColumns = function (self, column_table)
        -- requires columns as a table, with sub-columns for entries
        -- sub-columns need to be "left", "center", and/or "right"
            
            if column_table == nil then
                column_table = {}
                print("Error: Tried to initialize empty column list")

            end

            local has_left = false
            local has_center = false
            local has_right = false
            local column_n = 0 -- number of provided columns

            
            -- check for left column
            if (column_table.left == nil) or (column_table.left.entries == nil) then
                column_table.left = {} -- setting to empty instead of nil to avoid errors
                column_table.left.entries = {}
            else
                has_left = true
                column_n = column_n + 1
            end

            -- check for center column
            if (column_table.center == nil) or (column_table.center.entries == nil) then
                column_table.center = {}
                column_table.center.entries = {}
            else
                has_center = true
                column_n = column_n + 1
            end

            -- check for right column
            if (column_table.right == nil) or (column_table.right.entries == nil) then
                column_table.right = {}
                column_table.right.entries = {}
            else
                has_right = true
                column_n = column_n + 1
            end

            -- if all columns are empty, print an error (code after probably won't work)
            if not (has_left or has_center or has_right) then
                print("Error: Tried to initialize column without entries")
            end
            
            
            

            -- TODO: make function able to deal with setups of only "left & right", "center & right", etc.
            -- currently assumes 1 column = only left, 2 = left & center, 3 = left, right, and center
            

            if column_n == 1 then
            -- single column
                column_table.left.width = self.columns.width_total * self.columns.single_column_ratios[1]

            elseif column_n == 2 then
            -- dual column

                -- adjust width and x position for dual column layout
                column_table.left.width = self.columns.width_total * self.columns.dual_column_ratios[1]
                
                column_table.center.width = self.columns.width_total * self.columns.dual_column_ratios[2]
                column_table.center.x = column_table.left.x + column_table.left.width
            

            elseif column_n == 3 then
            -- triple columns

                -- adjust width and x position for triple column layout
                column_table.left.width = self.columns.width_total * self.columns.triple_column_ratios[1]
                
                column_table.center.width = self.columns.width_total * self.columns.triple_column_ratios[2]
                column_table.center.x = column_table.left.x + column_table.left.width

                column_table.right.width = self.columns.width_total * self.columns.triple_column_ratios[3]
                column_table.right.x = column_table.center.x + column_table.center.width
            else
                -- if we get here, an invalid number of clumns has been specified
                print("Error: Invalid number of specified columns for " .. self.header.title)
            end

            -- go through provided columns (left, center, right) and assign text, coordiates and height values
            for key, position in pairs(self.columns.positions) do
                local current_column = self.columns[position]

                if (current_column == nil) or current_column == {} then
                    -- if column is empty // nil skip it for the rest of the loop
                    -- workaround because Lua doesn't have a "continue" command
                    goto continue
                end

                -- initially always put the first column as active
                if current_column.index == 1 then
                    current_column.active = true
                else
                    current_column.active = false
                end

                -- make sure correct indeces are assigned to column entries
                current_column.entries = SetTableIndex(current_column.entries)

                -- go through all entries on the current column position and assign coordinates and size
                -- TODO: implement way to deal with too many rows / out of bounds entries
                for key_row, row in pairs(current_column.entries) do
                    local current_row = row -- this is only done for readability

                    -- initially always put the first row as active
                    if current_row.index == 1 then
                        current_row.active = true
                    else
                        current_row.active = false
                    end

                    -- assign type
                    if column_n == 1 then
                        current_row.type = SETTINGS.object_types.column_entry_main -- if only one column, font is different
                    else
                        current_row.type = SETTINGS.object_types.column_entry
                    end


                    -- determine height and vertical positions
                    current_row.height = self.getRowHeight(self.columns.height_row, current_row.type)

                    --TODO: "width" and "height" do not work here because I need width_total and height_total
                    -- todo figure out if above is still true
                    current_row.x = current_column.x -- x position is taken from parent column
                    current_row.y = current_column.y + (current_row.height * (current_row.index - 1) ) + (self.columns.margin_row * (current_row.index - 1)) -- y position is offset from parent column y position, based on index of the row item (this has to be dne because the rows are not indexed by number)
                    
                    -- determine width
                    current_row.width = current_column.width -- width is taken from parent column


                    -- transfer values back into entries of parent column
                    current_column[key_row] = current_row

                end

                -- transfer all values to the actual instance
                self.columns[position] = current_column

                -- add the buttons that are needed to display the entries later
                self.columns[position] = self:populateButtons(self.columns[position])
                
                --NOTE: leftover code from before the loop
                -- TODO: remove below if loop code works
                --[[ self.columns.center = self:populateButtons(self.columns.center)
                self.columns.right = self:populateButtons(self.columns.right) ]]

                -- workaround because Lua doesn't have a "continue" command
                ::continue::

            end
            
        end,

        initFooter = function (self, footer_tbl)
            if not footer_tbl then
                footer_tbl = {}
                print("Error: passed nil table to initFoter function")
                return
            end

            local footer_entries = footer_tbl.entries

            -- if footer entries are nil, assume they're empty instead
            if footer_entries == nil then
                footer_entries = {}
            end
            
            footer_entries = SetTableIndex(footer_entries)
            local entry_n = GetTableN(footer_entries)

            if entry_n > 0 then
                self.footer.accessible = true
            end
            
            -- if there are too many footnotes, reduce their width to still fit the section
            if ((self.footer.width_note * entry_n) + (footer.gap * (entry_n - 1))) > self.footer.width_total then
                self.footer.width_note = (self.footer.width_total / entry_n) - self.gap
            end

---@diagnostic disable-next-line: param-type-mismatch
            for key, entry in pairs(footer_entries) do
                -- shift x value from leftmost x value of entire footer section, based on index
                entry.x = self.footer.x + ((entry.index - 1) * self.footer.width_note) + (self.footer.gap * (entry.index - 1))
                -- y value is taken from parent footer
                entry.y = self.footer.y

                entry.width = self.footer.width_note
                entry.height = self.footer.height_note
                entry.text = entry.text or "No Text"

                -- transfer values to main footer object
                self.footer.entries[key] = entry
            end

            -- add the buttons that are needed to display the entries later
            self.footer = self:populateButtons(self.footer)

        end,

        -- this function generates the matrix that is used for keyboard navigation (currently also required for mouse highlighting)
        -- each button/entry from the different page elements and is assigned a coordinate
        -- todo implement "visible" behavior (shouldn't navigate to invisible buttons)
        -- todo the buttons do have a visible property now, so this should be handled once keyboard navigation is implemented
        -- todo update: visible property doesn't currently update properly
        generateNavMatrix = function (self)

            -- define local variables for easier use
            local matrix = {}
            local tab_entries = self.tabs.entries or {}
            local column_entries_left = self.columns.left.entries or {}
            local column_entries_center = self.columns.center.entries or {}
            local column_entries_right = self.columns.right.entries or {}
            local footer_entries = self.footer.entries or {}

            -- get number of actual entries per element
            local tab_entries_n = GetTableN(tab_entries)
            local column_entries_left_n = GetTableN(column_entries_left)
            local column_entries_center_n = GetTableN(column_entries_center)
            local column_entries_right_n = GetTableN(column_entries_right)
            local footer_entries_n = GetTableN(footer_entries)

            local max_column_entries = math.max(column_entries_left_n, column_entries_center_n, column_entries_right_n, 1) -- adding 1 here in case of 0 entries for correct offset of footer
            
            -- check how many columns are being used
            local columns_n = 0
            if column_entries_left_n > 0 then columns_n = columns_n + 1 end
            if column_entries_center_n > 0 then columns_n = columns_n + 1 end
            if column_entries_right_n > 0 then columns_n = columns_n + 1 end

            -- assigning y values, because up/down navigation is the main method of switching between page elements
            local tab_y = 0 -- start of tabs
            local column_y = 0 -- start of columns
            local footer_y = 0 -- start of footer

            -- since column entry index is vertical, their horizontal position depends on the parent column
            local column_x = {
                left = 1,
                center = 2,
                right = 3
            }
            
            -- if tab entries exist and should be accessible, they take the first row in navigation
            if tab_entries_n > 1 and self.tabs.accessible then
                tab_y = 1
                -- add all of the entries to the matrix
                for key, entry in pairs(tab_entries) do
                    local entry_x = entry.index
                    local entry_y = tab_y
                    -- if matrix is nil at this x-value, initialize empty array to avoid "indexing nil" error
                    if matrix[entry_x] == nil then
                        matrix[entry_x] = {}
                    end
                    
                    matrix[entry_x][entry_y] = self.tabs.entries[key].button
                end
            end

            -- columns always 1 layer below tabs
            if columns_n > 0 and self.columns.accessible then
                column_y = tab_y + 1
                

                -- left column
                
                if column_entries_left_n > 0 and self.columns.left.accessible then
                    -- if matrix is nil at this x-value, initialize empty array to avoid "indexing nil" error
                    if matrix[column_x["left"]] == nil then
                        matrix[column_x["left"]] = {}
                    end
                    

                    -- add all of the entries to the matrix
                    for key, entry in pairs(column_entries_left) do
                        local entry_x = column_x["left"]
                        local entry_y = column_y + entry.index - 1
                        matrix[entry_x][entry_y] = self.columns.left.entries[key].button
                    end
                end

                -- center column
                
                if column_entries_center_n > 0 and self.columns.center.accessible then
                    -- if matrix is nil at this x-value, initialize empty array to avoid "indexing nil" error
                    if matrix[column_x["center"]] == nil then
                        matrix[column_x["center"]] = {}
                    end

                    -- add all of the entries to the matrix
                    for key, entry in pairs(column_entries_center) do
                        local entry_x = column_x["center"]
                        local entry_y = column_y + entry.index - 1
                        matrix[entry_x][entry_y] = self.columns.center.entries[key].button
                    end
                end

                -- right column
                
                if column_entries_right_n > 0 and self.columns.right.accessible then
                    -- if matrix is nil at this x-value, initialize empty array to avoid "indexing nil" error
                    if matrix[column_x["right"]] == nil then
                        matrix[column_x["right"]] = {}
                    end
                    
                    -- add all of the entries to the matrix
                    for key, entry in pairs(column_entries_right) do
                        local entry_x = column_x["right"]
                        local entry_y = column_y + entry.index - 1
                        matrix[entry_x][entry_y] = self.columns.right.entries[key].button
                    end
                end
            end

            -- footer below last entry in columns
            if footer_entries_n > 0 and self.footer.accessible then
                footer_y = column_y + max_column_entries

                -- add all of the entries to the matrix
                for key, entry in pairs(footer_entries) do
                    local entry_x = entry.index
                    local entry_y = footer_y

                    -- if matrix is nil at this x-value, initialize empty array to avoid "indexing nil" error
                    if matrix[entry_x] == nil then
                        matrix[entry_x] = {}
                    end
                    
                    matrix[entry_x][entry_y] = self.footer.entries[key].button
                end
            end

            -- transfer values to object
            self.nav_matrix = matrix
            -- assign visibility
            self:assginNavMatrixVisibility()

            -- values for start and active are assigned to separate property "nav_values" because the matrix is supposed to only be indexed by numbers
            -- would have been better to do this as nav.matrix and nav.whateverelse, but it's too much effort to change atm
            self.nav_values = {}

            -- determine starting coordinates
            self.nav_values.start = self:getNavMatrixStart(self.nav_matrix)
            -- intitialize active entry at starting coordinates
            self.nav_values.active = self.nav_values.start
            -- then set starting value to active (for highlighting)
            self.nav_matrix[self.nav_values.active.x][self.nav_values.active.y].active = true

        end,

        -- This is a helper function to assign visibility values to all entries, where visibility is nil
        -- has to be called nav_matrix was generated / within generateNavMatrix function
        assginNavMatrixVisibility = function (self)
            for _x, column in pairs(self.nav_matrix) do
                for _y, entry in pairs(self.nav_matrix[_x]) do
                   if self.nav_matrix[_x][_y].visible == nil then
                    self.nav_matrix[_x][_y].visible = true -- default to true if value is nil 
                   end
                end
            end 
        end,

        -- This function returns the starting position of a given NavMatrix as X and Y
        getNavMatrixStart = function (self, _nav_matrix)
            local start_found = false
            local _x = 1
            local _y = 1
            local nav_entry = {}
            local nav_start = {
                x = _x,
                y = _y
            }



            while not start_found do
                nav_entry = _nav_matrix[_x][_y]
                -- if the entry is valid for navigation that's the one we want
                if nav_entry.visible then
                    start_found = true
                -- if it's not valid, but there are more y entries, move on
                elseif not (_nav_matrix[_x][_y + 1] == nil) then
                    _y = _y + 1
                -- if also not valid, move horizontally
                elseif not (_nav_matrix[_x + 1] == nil) then
                    if not (_nav_matrix[_x + 1][_y] == nil) then
                        _x = _x + 1
                    end
                else
                    -- something is wrong if we get here, but need to prevent infinite loop
                    start_found = true
                    print("Error: no navmatrix entries accessible and visible")
                end
                
            end

            nav_start.x = _x
            nav_start.y = _y

            return nav_start
            
        end,

        -- this function is used to navigate through a navMatrix, i.e. change the active entry
        -- requires _dx and _dy as integers to indicate movement direction. _dx = 1 --> 1 to the right, _dx = -1  --> 1 to the left etc.
        -- page must have a generated nav_matrix before using this function
        -- overwrites the values for active.x and active.y, which contains x and y
        navigateNavMatrix = function (self, _dx, _dy)
            -- nil value protection
            _dx = _dx or 0
            _dy = _dy or 0

            local _nav_matrix = self.nav_matrix
            local _nav_values = self.nav_values
            
            -- normalizing values to -1 / 1 because jumping multiple entries is more complicated to calculate
            if math.abs(_dx) > 1 then
                _dx = _dx / math.abs(_dx)
            end
            if math.abs(_dy) > 1 then
                _dy = _dy / math.abs(_dy)
            end


            local active_x, active_y = _nav_values.active.x, _nav_values.active.y
            local valid_entry = false
            
            
            local x_iterator = _dx
            local y_iterator = _dy

            local horizontal = (math.abs(_dx) > 0) -- is there movement in this direction?
            local vertical = (math.abs(_dy) > 0) -- is there movement in this direction?

            if horizontal and vertical then
                -- not supposed to have horizontal and vertical movement in parallel
                print("Error: wtf you're using the navigateNavMatrix function wrong, moron :)")
                return _nav_values.active -- don't move
            end

            -- To check if an entry is valid, it needs to be:
            -- not nil
            -- visible
            -- note: accsible doesn't need to be checked because non-accessible entries are not added to the nav_matrix

            while not valid_entry do

                -- adding this to prevent 'indexing nil value' errors
                if horizontal then
                    if _nav_matrix[active_x + _dx] == nil then
                        _dx = 0
                    end
                end


                if not (_nav_matrix[active_x + _dx][active_y + _dy] == nil) then
                    if _nav_matrix[active_x + _dx][active_y + _dy].visible then
                        active_x = active_x + _dx
                        active_y = active_y + _dy
                        valid_entry = true
                    else -- if the entry is not accessible or visible, iterate one more time for next loop
                        _dx = _dx + x_iterator
                        _dy = _dy + y_iterator
                    end
                
                elseif vertical and (not horizontal) then
                    -- if we're at the vertical limit of a row, it's fine to jump to the start of the next row
                    if not (_nav_matrix[1][active_y + _dy] == nil) then
                        active_x = 1
                    else
                        -- if there's also no entry in at x = 1, then don't move
                        active_x = _nav_values.active.x
                        active_y = _nav_values.active.y
                        valid_entry = true

                    end
                else -- if we get here, no valid iterative entry exists and we reset the coordinates to 1
                    active_x = _nav_values.active.x
                    active_y = _nav_values.active.y
                    valid_entry = true
                    
                end
            end

            -- if the value actully changed, assign it, and play sound effect
            if (not (self.nav_values.active.x == active_x)) or (not (self.nav_values.active.y == active_y)) then
                self.nav_values.active.x = active_x
                self.nav_values.active.y = active_y
                SOUND:playEffect(SOUND.sound_groups.menu.effects.hover)
                self:updateActiveEntry()
            end

        end,

        -- this function loops through all entries and updates their active status
        -- currently only used for keyboard navigation
        updateActiveEntry = function (self)
            for x_index, column in pairs(self.nav_matrix) do
                for y_index, entry in pairs(self.nav_matrix[x_index]) do
                    -- check if the current entry is registered as "active"
                    if (x_index == self.nav_values.active.x) and (y_index == self.nav_values.active.y) then
                        self.nav_matrix[x_index][y_index].active = true
                    else
                        self.nav_matrix[x_index][y_index].active = false
                    end
                end
            end
        end,



        drawBox = function (self, object)
            if object.visible == nil then object.visible = true end -- if no visible value assigned, assume true (could have worked with "hidden" instead, but this is at least consistent)

            if not object.visible then return end -- skip all of this if the object isn't visible anyways
            
            local outline = STYLE[object.type].outline
            local outline_color = STYLE[object.type].outline_color
            local fill = STYLE[object.type].fill
            local fill_color = STYLE[object.type].fill_color

            
            -- Scaled px values
            local _x, _y, _width, _height = ScaleObject(object.x, object.y, object.width, object.height)
            local _line_strength = ScalePx(STYLE[object.type].outline_strength)


            if outline then
                love.graphics.setColor(outline_color.r, outline_color.g, outline_color.b)
                love.graphics.setLineWidth(_line_strength)
                love.graphics.rectangle("line", _x, _y, _width, _height)
            end

            if fill then
                love.graphics.setColor(fill_color.r, fill_color.g, fill_color.b)
                love.graphics.rectangle("fill", _x, _y, _width, _height)
            end
        end,

        drawHeader = function (self)
            if self.header.visible == nil then self.header.visible = true end -- if no visible value assigned, assume true (could have worked with "hidden" instead, but this is at least consistent)    
            
            if self.header.button and self.header.visible then
                -- if header button exists, draw it (duh)
                self.header.button:draw()
            end
            
        end,

        drawTabs = function (self)
            
            -- if tabs exist for this page, check entries for buttons
            if self.tabs then
                for key, entry in pairs(self.tabs.entries) do

                    if entry.visible == nil then entry.visible = true end -- if no visible value assigned, assume true (could have worked with "hidden" instead, but this is at least consistent)    

                    -- if a button exists for this entry, draw it
                    if entry.button and entry.visible then
                        entry.button:draw()
                    end
                end
            end

            -- draw the tabs container box
            self:drawBox(self.tabs)
            

        end,

        drawColumns = function (self)
            
            -- if columns exist for this page
            if self.columns then

                -- check sub-columns for all possible positions
                for _, value in pairs(self.columns.positions) do
                    
                    -- if sub-column exists
                    if self.columns[value] then
                        
                        -- go through all entries for that sub-column
                        for key, entry in pairs(self.columns[value].entries) do

                            if entry.visible == nil then entry.visible = true end -- if no visible value assigned, assume true (could have worked with "hidden" instead, but this is at least consistent)    
    
                            -- if a button exists for this entry, draw it
                            if entry.button  and entry.visible then
                                entry.button:draw()
                            end
                        end
                    end
                    
                end
            end

        end,

        drawFooter = function (self)
            
            -- if a footer exist for this page, check entries for buttons
            if self.footer then
                for key, entry in pairs(self.footer.entries) do

                    if entry.visible == nil then entry.visible = true end -- if no visible value assigned, assume true (could have worked with "hidden" instead, but this is at least consistent)    

                    -- if a button exists for this entry, draw it
                    -- TODO: need to implement a check for visibility here later
                    if entry.button then
                        entry.button:draw()
                    end
                end
            end

        end,



        draw = function (self)

            self:drawHeader()
            self:drawTabs()
            self:drawColumns()
            self:drawFooter()

        end

    }
    
end

return Page
