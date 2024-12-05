require "globals"
local love = require"love"

DB = function (_db_path)

    local db = sqlite3.open(_db_path)
    local loadSchema = function (filepath)
        local file = io.open(filepath, "r")
        if not file then
            error("Could not open schema file: " .. filepath)
        end

        local schema = file:read("*a") -- read entire file
        file:close() -- close file again

        -- execute the schema in the database
        local result = db:exec(schema)
        if not (result == sqlite3.OK) then
            error("Error executing schema: " .. db:errmsg())
        end

        print("Schema loaded successfully!")
        
    end

    -- function returns # of entries in given table within db
    local countEntries = function (_table)
        local stmt = db:prepare("SELECT COUNT(*) FROM ?;", (_table))
        
        stmt:step()
        local count = stmt:get_uvalues() -- retrieves count as single value
        stmt:finalize()

        return count

    end



    return {
        db = db,
        loadSchema = loadSchema,
        countEntries = countEntries,

        -- This function tries to prepare a given statement and binds names from a given _names_object 
        -- and executes it if possible
        -- this is done as an extra step to catch errors
        tryStatement = function (self, _statement, _names_object)
            local stmt = self.db:prepare(_statement)

            if not stmt then
                print("SQL Error: " .. self.db:errmsg())
                print("Query: " .. _statement)
            else
                stmt:bind_names(_names_object)
                stmt:step()
                stmt:finalize()
                print("Statement preprared successfully: \n" .. _statement)
            end
        end,
    }
end

return DB

