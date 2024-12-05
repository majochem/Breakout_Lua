local love = require "love"
require "globals"

Brick = function ()
    local hp = 1
    local point_val = 1

    local fill_color = {
        r = 0.8,
        g = 0.8,
        b = 0.8
    }

    local line_color = {
        r = 1,
        g = 1,
        b = 1
    }


    -- this has the values for color shift based on properties
    local fill_color_shift = {
        -- values in array are r,g,b
        [0] = {r = 1.0, g = 1.0, b = 1.0}, -- no shift
        [1] = {r = 0.8 ,g = 0.8, b = 0.8}, -- slightly darker
        [2] = {r = 1.0, g = 1.0, b = 0.0}, -- yellow
        [3] = {r = 0.5, g = 1.0, b = 0.0}, -- lime
        [4] = {r = 0.0 ,g = 1.0, b = 0.0}, -- green
        [5] = {r = 1.0, g = 0.5, b = 0.0}, -- orange
        [6] = {r = 1.0, g = 0.0, b = 0.0}, -- red
        [7] = {r = 1.0, g = 0.0, b = 0.5}, -- magenta
        [8] = {r = 1.0, g = 0.0, b = 1.0}, -- pink
        [9] = {r = 0.5, g = 0.0, b = 1.0}, -- purple
        [10] = {r = 0.0, g = 0.0, b = 1.0}, -- blue

        X = {r = 0.5, g = 0.5, b = 0.5}, -- darker
        B = {r = 0.7, g = 0.7, b = 0.0}, -- dark yellow
    }

    local line_color_shift = fill_color_shift -- take default values
    
    -- change only values for special cases
    line_color_shift.X = {r = 0.2, g = 0.2, b = 0.2} -- much darker
    line_color_shift.B = {r = 0.7, g = 0.0, b = 0.0} -- dark red
    



    -- width of individual bricks takes into account screen width minus area that is lost for playable area
    local width = SCR_WIDTH * BRICK_WIDTH_RATIO * (1 - (AREA_SIDE_RATIO * 2))
    local height = SCR_HEIGHT * BRICK_HEIGHT_RATIO * (1 - AREA_BOTTOM_RATIO - AREA_TOP_RATIO) * (GRID_AREA_RATIO)

    -- sounds
    local effect = {
        destructable = SOUND.sound_groups.ball.effects.bounce_brick,
        indestructable = SOUND.sound_groups.ball.effects.bounce_brick_x
    }



    return {
        fill_color = fill_color,
        line_color = line_color,
        line_strength = 0, -- initialized at 0, changed in setBrickProperties
        hp = hp,
        point_val = point_val,
        width = width,
        height = height,
        x = 0,
        y = 0,
        type = "brick",
        variant = 1,
        destructable = true, -- todo implement dynamic assignment of destructable value based on brick type/variant
        empty = false, -- if empty brick, they'll be removed from the grid afterwards, but is needed for correct coordinates

        hitResponse = function (self)
        -- this function is triggered when a brick is hit
        -- if the brick is destructable then it will reduce hp until 0
        -- returns destroy (boolean) and points (integer)

            local destroy = false
            local points = 0
            -- todo implement way for more than one damage per ball
            local dmg_placeholder = 1

            if self.destructable then
                self.hp = self.hp - dmg_placeholder
                -- adjust colors according to new hp values
                local is_update = true
                SOUND:playEffect(effect.destructable)
                self:setColors(is_update)
            else
                SOUND:playEffect(effect.indestructable)

            end

            if self.hp <= 0 then
                destroy = true
                points = self.point_val
            end


            return destroy, points

        end,

        -- takes in a determining character from a level map and assigns brick properties based on that
        setBrickProperties = function (self, char)
            -- Short summary to types of bricks: [If you change this, you also need to change the description and logic in Brick.lua]
            -- X = indestructable
            -- number 0 = empty slot
            -- numbers 1 to 9 = normal brick with that amount of hit points
            -- B = bomb, i.e. exploding brick (not yet implemented)

            char = char or "0"
            local is_number = false

            -- check if it's a number, b/c then logic is easier later
            if (char == "0") or
                (char == "1") or
                (char == "2") or
                (char == "3") or
                (char == "4") or
                (char == "5") or
                (char == "6") or
                (char == "7") or
                (char == "8") or
                (char == "9")
                then
                    char = tonumber(char)
                    is_number = true
            end

            self.variant = char
            
            if is_number then
                
                if char == 0 then
                    self.destructable = false
                    self.empty = true
                    self.hp = 0
                    self.point_val = 0
                else
                    self.destructable = true
                    self.empty = false
                    self.hp = char
                    self.point_val = char
                end

            else
                -- indestructable
                if char == "X" then
                    self.destructable = false
                    self.empty = false
                    self.hp = 1
                    self.point_val = 0
                elseif char == "B" then
                    self.destructable = true
                    self.empty = false
                    self.hp = 1
                    self.point_val = 1
                    self.has_function = true
                    self.func = function ()
                        --todo implement special function handling
                        print("This is a placeholder for future special functions")
                    end
                end
            end

            -- colors assigned by separate function ( as it needs to happen in multiple places)
            self:setColors()
            self.line_strength = STYLE[self.type].outline_strength
            
        end,

        -- Sets the color values of a brick
        -- if it is an update after getting hit, "is_update" should be set to true
        setColors = function (self, is_update)
            is_update = is_update or false -- probably redundant because nil counts as false

            -- if the variant is a number, it's a regular brick and color adjusts based on hp
            if type(self.variant) == "number" then
                self.fill_color = GetColorShift(fill_color.r,fill_color.g, fill_color.b, fill_color_shift[self.hp].r,  fill_color_shift[self.hp].g,  fill_color_shift[self.hp].b)

                -- line color is only change if it's not an update
                if is_update then return end
                self.line_color = GetColorShift(line_color.r, line_color.g, line_color.b, line_color_shift[self.hp].r, line_color_shift[self.hp].g, line_color_shift[self.hp].b)
            
            -- if it's a special type, the color is independent of hp value
            else
                self.fill_color = GetColorShift(fill_color.r,  fill_color.g,  fill_color.b, fill_color_shift[self.variant].r, fill_color_shift[self.variant].g, fill_color_shift[self.variant].b)

                -- line color is only change if it's not an update
                if is_update then return end
                self.line_color = GetColorShift(line_color.r, line_color.g,  line_color.b,  line_color_shift[self.variant].r, line_color_shift[self.variant].g, line_color_shift[self.variant].b)
            end
            
        end



    }

    
end

return Brick