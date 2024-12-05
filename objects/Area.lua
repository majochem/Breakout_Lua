local love = require "love"
require "globals"

Area = function ()
    local type = "play_area"
    local color = STYLE[type].outline_color
    local line_strength = STYLE[type].outline_strength

    -- todo fetch color information dynamically?
    local death_zone_color_shift = {
        r = 0.5,
        g = 0.1,
        b = 0.1
    }

    local death_zone_color = GetColorShift(color.r, color.g,color.b, death_zone_color_shift.r, death_zone_color_shift.g, death_zone_color_shift.b)

    
    return {
        width = SCR_WIDTH - (SCR_WIDTH * AREA_SIDE_RATIO * 2),
        height = SCR_HEIGHT - (SCR_HEIGHT * AREA_TOP_RATIO) - (SCR_HEIGHT * AREA_BOTTOM_RATIO),
        x = SCR_WIDTH * AREA_SIDE_RATIO,
        y = SCR_HEIGHT * AREA_TOP_RATIO,
        death_zone = {},


        color = color,
        death_zone_color = death_zone_color,

        draw = function (self)
            -- Scaled px values
            -- self
            local _x, _y, _width, _height = ScaleObject(self.x, self.y, self.width, self.height)
            local _line_strength = ScalePx(line_strength)

            -- death zone
            local _death_zone_x, _death_zone_y, _death_zone_width, _death_zone_height = ScaleObject(self.death_zone.x, self.death_zone.y, self.death_zone.width, self.death_zone.height)

            -- Draw rectangles
            -- death zone
            love.graphics.setColor(self.death_zone_color.r, self.death_zone_color.g, self.death_zone_color.b)
            love.graphics.rectangle("fill", _death_zone_x, _death_zone_y, _death_zone_width, _death_zone_height)
            
            -- main area
            love.graphics.setColor(self.color.r, self.color.g, self.color.b)
            love.graphics.setLineWidth(_line_strength)            
            love.graphics.rectangle("line", _x, _y, _width, _height)
            

        end,

        initDeathZone = function (self)
        -- sets up the death zone for the ball
        -- doing this in a function because I want to dynamically respond to Area size changes and don't know how else to do it
            self.death_zone = {
                x = self.x,
                y = self.y + self.height - (AREA_DEATH_ZONE_THICKNESS_RATIO * SCR_HEIGHT),
                height = AREA_DEATH_ZONE_THICKNESS_RATIO * SCR_HEIGHT,
                width = self.width
            }


        end,

        getBorder = function (self, direction)
            -- requires direction of area border as string. Accepted: "left", "right", "top", "bottom"
            -- returns border as a table object with x,y, height and width
            local directions = {"left","right", "top", "bottom"}
            
            
            local border = {
                x = 0,
                y = 0,
                width = 0,
                height = 0,
                type = "border"
            }

            -- looping through directions one by one
            -- vertical borders have no width and horizontal borders have no height
            -- could have been done as multidimensional table lookup to save space, but would have hurt readability
            --for _, entry in pairs(directions) do
                if (direction == "left") then

                    border.x = self.x
                    border.y = self.y
                    border.width = -1 -- negative because I want buffer to the left
                    border.height = self.height
                    return border
                elseif (direction == "right") then
                    border.x = self.x + self.width
                    border.y = self.y
                    border.width = 1
                    border.height = self.height
                    return border
                elseif (direction == "top") then
                    border.x = self.x
                    border.y = self.y
                    border.width = self.width
                    border.height = - 1 -- negative because I want buffer to the top
                    return border
                elseif (direction == "bottom") then
                    border.x = self.x
                    border.y = self.y + self.height
                    border.width = self.width
                    border.height = 1
                    return border
                else
                    print("Error: Invalid direction argument")
                    return border
                    
                end
            --end
            


            
        end
    }
end

return Area