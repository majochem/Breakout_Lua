require  "globals"
local love = require "love"
local lunajson = require "lunajson"

Highscore = function()

    local file_path = "src/savefiles/highscores.json"
    local scores_key = "HighScores" -- reference key that's used for the first level of the json file
    local score_file = love.filesystem.read(file_path)
    local data -- base data (go into [scores_key] to be able to reference actual highscore slots)

    local datakey = {
        name = "name",
        score = "score",
        date = "date"
    }

    -- setting up functions to check for correct formatting
    local dataValid = {}
    
    -- checks if string
    dataValid[datakey.name] = function (_value)
        return IsString(_value)
    end

    -- checks if number
    dataValid[datakey.score] = function (_value)
        return IsNumber(_value)
    end

    -- checks for ISO date format
    dataValid[datakey.date] = function (_value)
        return IsISODate(_value)
    end



    
    -- file nil value protections
    if not score_file then
        error("No highscore file found at: " .. file_path)
    else
        data = lunajson.decode(score_file)
    end

    if not data then
        error("No highscore data found at: " .. file_path)
    else
        data.scores = data[scores_key] -- This is to ensure that the first table level is based on the slot IDs
    end

    local num_score_slots = GetTableN(data.scores)

    -- writes new (already checked data to the file)
    local saveFile = function (_file_path, _data)
        if (_file_path == nil) or (_data == nil) then
            error("Invalid file_path of data")
        end

        -- have to reformat data to use the correct indexing key
        local format_data = {}
        format_data[scores_key] = _data.scores

        local encoded_data = JSONPrettyPrint(lunajson.encode(_data))

        local file = io.open(_file_path, "w")
        if not file then error("Cannot open file for writing: " .. _file_path) end
        file:write(encoded_data) -- Save the updated JSON
        file:close()
    end

    return {
        data = data,
        datakey = datakey,
        high_score = 0, -- initialize at 0, change later
        low_score = 0, -- initialize at 0, change later

        
        -- needs to be called to initialize the correct values
        -- couldn't figure out how to have this as a local function b/c I needed "self"
        init = function (self)
            -- todo further init functions?
            self:getTopAndBottomScore()    
        end,

        -- gets highest and lowest entry score from the json/saved table and assigns it to the object
        getTopAndBottomScore = function (self)
            self.high_score = self:getData(1, datakey.score) -- this assumes that values are entered in correct order
            self.low_score = self:getData(num_score_slots, datakey.score)
        end,

        

        -- Requies self, an index and a key for the data that is to be retrieved.
        -- valid keys contained in datakey table
        -- returns value at given index if one exists, otherwise returns nil or an error
        getData = function (self, _index, _datakey)
            if (_index ~= nil) and (_datakey ~= nil) then
                _index = tostring(_index) -- make sure it's a string, in case a number was provided
            else
                error("Provided nil value as parameter\n" ..
                "Index: " .. _index ..
                "Datakey: " .. _datakey
                )
            end

            local new_data = self.data.scores[_index]
            local output
            
            if new_data ~= nil then
                output = new_data[_datakey]
            else
                error("Invalid index: " .. _index)
            end
            
            return output
            
        end,

        -- this function updates both the current object's value, as well as the one in the saved file
        updateData = function(self, _index, _datakey, _value)
            if (not _index == nil) and (not _datakey == nil) then
                _index = tostring(_index) -- make sure it's a string, in case a number was provided
            else
                error("Provided nil value as parameter\n" ..
                "Index: " .. _index ..
                "Datakey: " .. _datakey
                )
            end

            local new_data = self.data.scores[_index]
            
            if new_data == nil then
                error("Invalid index: " .. _index)
            end

            local valid_datakey = TableContainsValue(datakey, _datakey)

            if not valid_datakey then
            error("Invalid datakey: " .. _datakey)
            end

            local valid_value = dataValid[_datakey](_value) -- dataValid contains functions, according to respective key

            if valid_value then
                self.data.scores[_index][_datakey] = _value
                saveFile(file_path, self.data)
            else
                error("Invalid value type\n" ..
                "Index: " .. _index ..
                "Datakey: " .. _datakey ..
                "Value: " .. _value
                )
            end
        end,

        -- Checks if score is higher than any score in highscores.json
        -- returns false or the index of the rank it would take
        isHighScore = function (self, _score)
            local rank -- this will be overwritten with index, if high enough
            local index = num_score_slots -- used to count down (check lowest score first)
            local exit = false -- used to break loop (don't want to use goto)
            
            -- using a while loop, because I couldn't figure out how to make it work with a negative for loop
            while (not exit) and (index > 0) do

                if self.data.scores[tostring(index)] == nil then
                    print("stop here")
                end
                
                if _score > self.data.scores[tostring(index)][datakey.score] then
                    -- if score is bigger than current value, update rank and continue
                    rank = tostring(index) -- need to convert to string because the key is not a number
                else 
                    -- if it's not bigger, exit the loop (rank will remain "nil" if this happens during first loop)
                    exit = true

                end
                index = index - 1
            end

            return rank
        end,

        insertScore = function (self, _entry, _index)
            
            self:checkEntryStructure(_entry) -- make sure format is correct
                
            local prev_entry = {}
            local next_entry = _entry

            for i = tonumber(_index), num_score_slots do
                prev_entry = self.data.scores[tostring(i)] -- save previous entry
                self.data.scores[tostring(i)] = next_entry -- enter new values
                next_entry = prev_entry -- transfer saved values to next slot
            end

            saveFile(file_path, self.data) -- update the json file

        end,

        checkEntryStructure = function (self,_entry)
            -- check size matches
            if GetTableN(datakey) ~= GetTableN(_entry) then
                error("Invalid entry structure size")
            end

            -- check all properties are non-nil
            for key, value in pairs(datakey) do
                if _entry[key] == nil then
                    error("Invalid entry: " .. key .. "is nil value")
                end
            end

        end,

        -- DEBUG FUNCTIONS
        debugPrintAllEntries = function (self)
            local output_str

            for index, entry in pairs(self.data.scores) do
                for key, value in pairs (entry) do
                    output_str = index .. " - " .. key .. ": " .. value .. "\n"
                    print(output_str)
                    
                end
            end
        end

    }

end

return Highscore
