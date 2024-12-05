-- This file contains all the pre-determined level maps (i.e. which type of brick populates the grid)
--as well as potential logic for auto-generating further levels

require "globals"
local love = require "love"

LevelMaps = function ()

    -- a level map consists of 10 arrays, which contain strings with 10 characters each
    -- certain characters are assigned special meanings

    -- Short summary to types of bricks: [If you change this, you also need to change the description and logic in Brick.lua]
    -- X = indestructable
    -- number 0 = empty slot
    -- numbers 1 to 9 = normal brick with that amount of hit points
    -- B = bomb, i.e. exploding brick (not yet implemented)
    

    local level_map = {}

    -- level 1
    level_map[1] = {
        [0] = "1111111111",
        [1] = "1111111111",
        [2] = "1111111111",
        [3] = "1111111111",
        [4] = "1111111111",
        [5] = "1111111111",
        [6] = "1111111111",
        [7] = "1111111111",
        [8] = "1111111111",
        [9] = "1111111111",
    }
    -- level 2
    level_map[2] = {
        [0] = "2222222222",
        [1] = "1111111111",
        [2] = "1111111111",
        [3] = "1111111111",
        [4] = "1111111111",
        [5] = "1111111111",
        [6] = "1111111111",
        [7] = "1111111111",
        [8] = "2222222222",
        [9] = "2222222222",
    }

    -- level 3
    level_map[3] = {
        [0] = "3333333333",
        [1] = "3111111113",
        [2] = "3111111113",
        [3] = "3111111113",
        [4] = "3111221113",
        [5] = "3111221113",
        [6] = "3111111113",
        [7] = "3111111113",
        [8] = "3111111113",
        [9] = "3333333333",
    }
    
    -- level 4
    level_map[4] = {
        [0] = "3333333333",
        [1] = "3222222223",
        [2] = "3211111123",
        [3] = "3211111123",
        [4] = "3211XX1123",
        [5] = "3211XX1123",
        [6] = "3211111123",
        [7] = "3211111123",
        [8] = "3222222223",
        [9] = "333XXXX333",
    }

    -- Level 5 (Currently just for testing)
    level_map[5] = {
        [0] = "0000000000",
        [1] = "9999999999",
        [2] = "8888888888",
        [3] = "7777777777",
        [4] = "6666666666",
        [5] = "5555555555",
        [6] = "4444444444",
        [7] = "3333333333",
        [8] = "2222222222",
        [9] = "1111111111",
    }


    return {
        level_map = level_map,

        getLevelMap = function (level)
            level = level or 1

            local output_map = level_map[level]
            if output_map == nil then output_map = level_map[1] end

            return output_map
            
        end


        

    }
end

return LevelMaps