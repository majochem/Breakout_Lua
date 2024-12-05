require "globals"
local love = require "love"
local Brick = require "objects.Brick"
local LevelMaps = require "objects.LevelMaps"

LevelGrid = function (player)

    local max_col = 1 / BRICK_HEIGHT_RATIO -- this is 10 by default
    local max_row = 1 / BRICK_WIDTH_RATIO -- -- this is 10 by default

    
    
    
    local grid ={}
    
    

    return {
        grid = grid,
        max_col = max_col,
        max_row = max_row,
        grid_generated = false,
        

        x = (SCR_WIDTH * AREA_SIDE_RATIO) + (SCR_WIDTH * GRID_X_BUFFER_RATIO),
        y = (SCR_HEIGHT * AREA_TOP_RATIO) + (SCR_HEIGHT * GRID_Y_BUFFER_RATIO),

        fillGrid = function (self)

            local current_map = LevelMaps().getLevelMap(player.level)

            for i = 1, self.max_row, 1 do
                self.grid[i] = {}
                local map_row = current_map[i-1] -- this returns a string from the level map

                self.grid[i].y_index = i -- this is so the row remembers it's original position, but means I'll have to use ipairs instead of pairs later

                for j = 1, self.max_col, 1 do
                    
                    self.grid[i][j] = Brick()
                    self.grid[i][j].x = self.x + (self.grid[i][j].width * (j-1))
                    self.grid[i][j].y = self.y + (self.grid[i][j].height * (i-1))
                    self.grid[i][j].x_index = j
                    
                    -- assign variant dependent properties
                    local variant = string.sub(map_row, j, j) -- returns the char at pos j
                    if variant == "" then 
                        print("stop here") 
                    end

                    self.grid[i][j]:setBrickProperties(variant)
                    
                end
                
            end

            self.grid_generated = true
            
        end,

        --todo regenerate / load grid (also for Brick)
        

        draw = function (self)

            --todo fix coloring for variants with lowered hp
            

            for i = 1, max_row do
                if self.grid[i] == nil then
                    goto next_row
                end
                
                for j = 1, max_col do
                    local brick = self.grid[i][j]

                    if not (brick == nil) then
                        -- Scaled px values
                        -- self
                        local _x, _y, _width, _height = ScaleObject(brick.x, brick.y, brick.width, brick.height)

                        love.graphics.setColor(brick.fill_color.r, brick.fill_color.g, brick.fill_color.b)
                        love.graphics.rectangle("fill", _x, _y, _width, _height)
                        love.graphics.setLineWidth(ScalePx(brick.line_strength))
                        love.graphics.setColor(brick.line_color.r, brick.line_color.g, brick.line_color.b)
                        love.graphics.rectangle("line", _x, _y, _width, _height)
                    end

                    
                end

                ::next_row::
                
            end
            
        end,
        -- checks if there are no more bricks in the grid. returns true then, otherwise returns false
        isEmpty = function (self)
            
            for i = 1, self.max_row do
                if not (self.grid[i] == nil) then
                    for j = 1, max_col do
                        if not (self.grid[i][j] == nil) then 
                            return false -- this should only happen if there is a brick left
                        end
                    end
                end
            end

            return true
            
        end,

        --todo account for nil values
        getSaveData = function (self)
            local save_grid ={
                id = self.id,
                rows = {},
            }

            -- have to use loop from 1 to max_row/max_col because ipairs stops at first nil, and pairs doesn't work
            for i = 1, self.max_row do
                local row = self.grid[i]
                
                
                if row == nil then 
                    goto next_row -- used because no break loop in Lua
                end

                row.id = self:getRowId(row.y_index)
                save_grid.rows[row.y_index] = {
                    id = row.id,
                    y_index = row.y_index,
                    grid_id = self.id,
                    bricks = {} -- initialize empty brick table
                }

                for j = 1, self.max_col do
                    local brick = self.grid[i][j]
                    
                    if not (brick == nil) then 
                        save_grid.rows[row.y_index].bricks[brick.x_index] = {
                            id =  self:getBrickId(row.id, brick.x_index), -- id calculated based on row_id
                            row_id = row.id,
                            x_index = brick.x_index,
                            variant = tostring(brick.variant),
                            current_hp = brick.hp,
                            destroyed = false}
                    end

                end

                ::next_row::
            end

            return save_grid


        end,

        -- This function updates the grid and brick properties based on a loaded save filename
        -- requires a properly formated save file table, i.e. grid.rows[n].bricks[n]
        updateFromSave = function (self, _grid_save)
            self:fillGrid() -- initialize new grid

            local new_grid = {}


            -- fetch / assign all the correct properties to bricks that were saved
            for i, row in ipairs(_grid_save.rows) do

                if new_grid[row.y_index] == nil then
                    new_grid[row.y_index] = {} -- initiallize if completely empty
                end

                if new_grid[row.y_index].y_index == nil then
                    new_grid[row.y_index].y_index = row.y_index -- assign y_index value, if empty
                end

                for __, brick in ipairs(row.bricks) do
                    -- copy current base values of brick
                    local temp_brick = self.grid[row.y_index][brick.x_index]

                    -- overwrite saved properties
                    temp_brick.id = brick.id
                    temp_brick.variant = brick.variant
                    temp_brick:setBrickProperties(temp_brick.variant) -- set initial properties
                    -- if hp has changed from default
                    if temp_brick.hp ~= brick.current_hp then
                        temp_brick.hp = brick.current_hp -- update hp in case it was already lowered
                        temp_brick:setColors(true) -- update color, passing in "true" for is_update because it's updating color based on hp value
                    end
                    temp_brick.destroyed = brick.destroyed
                    temp_brick.x_index = brick.x_index

                    -- write updated values in new grid. this way, only the saved bricks are transferred
                    new_grid[row.y_index][brick.x_index] = temp_brick

                end

            end

            -- overwrite object grid with the new one
            self.grid = new_grid
            

            
            
        end,

        getRowId = function (self, _y_index)
            local grid_id = self.id
            local row_id = (grid_id * 1000) + _y_index

            return row_id
        end,

        -- grid_id is currently hardcoded to be equal to save_slot_id, as there's no real reason to keep grids not tied to save slots
        getGridId = function (self, _save_id)
            _save_id = _save_id
            self.id = _save_id
        end,

        getBrickId = function (self, _row_id, _x_index)
            local brick_id = (_row_id * 1000) + _x_index

            return brick_id

        end


    }
end

return LevelGrid