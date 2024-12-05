require "globals"
local love = require "love"
local DB = require "components.DB"
local Highscore = require "components.Highscore"

Saves = function ()

    -- HIGHSCORE SAVEFILE
    local highscore = Highscore() -- create object instance
    highscore:init() -- assigns top and bottom scores (for now)

    -- SAVESTATE DATABASE

    local db_path = "src/savefiles/savestates.db"
    local schema_path = "src/templates/SaveFileTableSchema.sql"
    local save_db = DB(db_path)
    
    save_db.loadSchema(schema_path) -- initialze database

    local max_save_slots = 10

    local save_statement = {
        player = [[INSERT OR REPLACE INTO player (id, name, paddle_x, score, level, lives, ball_id) VALUES (:id, :name, :paddle_x, :score, :level, :lives, :ball_id)
        ]],

        ball = [[INSERT OR REPLACE INTO ball (id, x, y, angle_rad, speed) VALUES (:id, :x, :y, :angle_rad, :speed)
        ]],

        grid = [[INSERT OR REPLACE INTO grid (id) VALUES (:id) ]],

        grid_row = [[INSERT OR REPLACE INTO grid_row (id, grid_id, y_index) VALUES (:id, :grid_id, :y_index)
        ]],

        grid_brick = [[INSERT OR REPLACE INTO grid_brick (id, row_id, x_index, variant, current_hp, destroyed) VALUES (:id, :row_id, :x_index, :variant, :current_hp, :destroyed) 
        ]],

        game = [[INSERT OR REPLACE INTO game (id, date_time, player_id) VALUES (:id, :date_time, :player_id) 
        ]],

    }

    local load_statement = {
        game = [[SELECT * FROM game WHERE id = ?]],
        player = [[SELECT * FROM player WHERE id = ?]],
        ball = [[SELECT * FROM ball WHERE id = ?]],
        grid = [[SELECT * FROM grid WHERE id = ?]],
        grid_row = [[SELECT * FROM grid_row WHERE grid_id = ?]],
        grid_brick = [[SELECT * FROM grid_brick WHERE row_id = ?]],
    }

    local delete_statement = {
        game = [[DELETE FROM game WHERE id = ?]],
        player = [[DELETE FROM player WHERE id = ?]],
        ball = [[DELETE FROM ball WHERE id = ?]],
        grid = [[DELETE FROM grid WHERE id = ?]],
        grid_row = [[DELETE FROM grid_row WHERE grid_id = ?]],
        grid_brick = [[DELETE FROM grid_brick WHERE row_id = ?]],
    }

    -- saves a specific game object. e.g., player, ball, etc.
    local saveObject = function (_save_object, _statement)

        save_db:tryStatement(_statement, _save_object)
        
    end

    -- this function requires a properly formatted _grid_save table, see LevelGrid module
    local saveGrid = function (_grid_save)
        local stmt = save_db.db:prepare(save_statement.grid)

        -- save overall grid first
        save_db:tryStatement(save_statement.grid, _grid_save)
        
        
        -- go through all rows of the grid and save them
        for _, row in ipairs(_grid_save.rows) do

            save_db:tryStatement(save_statement.grid_row, row)
            
            -- within each row, go through every brick and save those
            for _, brick in ipairs(row.bricks) do

                save_db:tryStatement(save_statement.grid_brick, brick)
            end
        end
        
    end

    local saveState = function (_save_state)
    
        local game_save = _save_state.game -- contains save slot id, game time etc. 
        local player_save = _save_state.player -- contains all player data
        local ball_save = _save_state.ball -- contains ball data
        local grid_save = _save_state.grid -- contains data of grid, rows, and bricks

        saveObject(game_save, save_statement.game)
        saveObject(player_save, save_statement.player)
        saveObject(ball_save, save_statement.ball)
        saveGrid(grid_save) -- grid works differently and has a separate function

    end

    -- Function requires statement from load_statement and the id to be matched
    -- returns a lua table with contents of the db table for the statement
    local loadTable = function (_statement, 
        _id, -- id that will be used for matching placeholder in query
        _index -- if a specific index of a multirow result is desired, must be 1 if only 1 row is expected
    )

        
        if _id == nil then -- check for nil
            error("Loading table with id == nil, for: " .. _statement)
        end

        local stmt = save_db.db:prepare(_statement)
        stmt:bind_values(_id) -- this assigns the id to the placeholder value

        local table_out = {} -- not using 'table' because it's a problematic term in lua

        --[[ while stmt:step() do
            local row = stmt:get_named_values()
            table.insert(table_out, row)
        end ]]

        for row in stmt:nrows() do -- loop through all rows that match the query
            table.insert(table_out, row) -- insert values for the current row into the table
        end

        stmt:finalize()

        if not (_index == nil) then
            table_out = table_out[_index]
        end

        return table_out

    end

    -- Function returns a full save_state table for a given slot_id
    -- returns an error if there's no entry for the given
    local loadSaveState = function (_slot_id)
        local save_state = {
            game = {},
            player = {},
            ball = {},
            grid = {},
        }
        
        save_state.game = loadTable(load_statement.game, _slot_id, 1)
        
        -- check for empty save states
        if (save_state.game == {}) then
          error("No save state at position: " .. _slot_id)
        end

        save_state.player = loadTable(load_statement.player, save_state.game.player_id, 1)
        save_state.ball = loadTable(load_statement.ball, save_state.player.ball_id, 1)

        -- todo grid_id is currently assumed to be equal to player_id, but it's not represented in data structure
        save_state.grid = loadTable(load_statement.grid, save_state.player.id, 1)

        -- rest of grid loading is more complicated
        -- start with main grid and get all rows, where grid_id matches
        save_state.grid.rows = loadTable(load_statement.grid_row, save_state.grid.id )
        if save_state.grid.rows == nil then
            error("No rows found in grid with id: " .. save_state.grid.id)
        end

        -- find bricks in each row
        for i, row in ipairs(save_state.grid.rows) do
            -- load bricks where row_id matches
            save_state.grid.rows[i].bricks = loadTable(load_statement.grid_brick, row.id)
        end

        return save_state


    end

    -- Deletes according to the predefined delete_statements
    local deleteTable = function (_statement, _id)
        if _id == nil then -- check for nil
            error("Deleting table with id == nil, for: " .. _statement)
        end

        --[[ save_db:tryStatement(_statement, _id) ]]
        local stmt = save_db.db:prepare(_statement)
        stmt:bind_values(_id) -- this assigns the id to the placeholder value
        stmt:step()
        stmt:finalize()

    end

   

    local save_slot_defaults = {
        name = LANG.default.empty_string,
        date_time = LANG.default.empty_string,
    }

    -- initialize empty save slots
    local save_slots = {}
    for i = 1, max_save_slots do
        save_slots[i] = {
            id = i,
            name = save_slot_defaults.name,
            date_time = save_slot_defaults.date_time
        }
    end




    

    return {
        saveObject = saveObject,
        saveGrid = saveGrid,
        saveState = saveState,
        loadTable = loadTable,
        loadSaveState = loadSaveState,
        deleteTable = deleteTable,
        save_slot_defaults = save_slot_defaults,
        save_slots = save_slots,
        highscore = highscore,

        -- initializes the values of save slots used for display purposes
        -- should be called during load function in main and after every change to saves
        updateSaveSlots = function (self)
            for i, slot in pairs(self.save_slots) do
                -- if the slot isn't "empty", load in the actual data
                if (slot.name ~= save_slot_defaults.name) and (slot.date_time ~= save_slot_defaults.date_time) then
                    local data = loadSaveState(i) -- using local data variable because not all values will be stored permanently
                    self.save_slots[i].name = data.player.name
                    self.save_slots[i].date_time = data.game.date_time
                end
            end

        end,

        -- This function deletes an entry in the provided slot
        deleteSaveSlot = function (self, _slot_id)
             -- deletes all save state data at a given id
    
            if _slot_id == nil then -- check for nil
                error("Deleting save state with id == nil")
            end

            if (save_slots[_slot_id].name == save_slot_defaults.name) and (save_slots[_slot_id].date_time == save_slot_defaults.date_time) then
                -- save slot is already empty
            else
                -- else set them to empty now
                save_slots[_slot_id].name = save_slot_defaults.name
                save_slots[_slot_id].date_time = save_slot_defaults.date_time
            end

            local slot_check = loadTable(load_statement.game, _slot_id, 1)
            if slot_check == nil then return end -- if there's no save data at this slot, no reason to delete

            -- todo: future improvement - bind all necessary IDs to the slot_id so there's no need to load all data
            local save_state = loadSaveState(_slot_id)
            deleteTable(delete_statement.game, save_state.game.id)
            deleteTable(delete_statement.player, save_state.game.player_id)
            deleteTable(delete_statement.ball, save_state.player.ball_id)
            deleteTable(delete_statement.grid, save_state.grid.id)

            for i, row in pairs(save_state.grid.rows) do
                -- delete all rows in db
                deleteTable(delete_statement.grid_row, save_state.grid.id)
                    -- delete all corresponding bricks in db for this row_id
                    for j, brick in pairs(row.bricks) do
                        deleteTable(delete_statement.grid_brick, row.id)
                    end
            end




        end



    }
end

return Saves