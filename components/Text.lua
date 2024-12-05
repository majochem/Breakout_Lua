require "globals"

local love = require "love"
local Font = require "components.Font"


Text = function (x, y, text, width, height, font_size, color, h_align, v_align, opacity)
    
    -- fallback declaration for arguments
    x = x or 0
    y = y or 0
    text = text or "No Text"
    height = height or (40 * SCR_SCALE_HEIGHT)
    width = width or  (80 * SCR_SCALE_WIDTH)
    font_size = font_size or "p1"
    h_align = h_align or "left"
    v_align = v_align or "middle"
    opacity = opacity or 1


    local font = Font() -- this will not be returned

    
    
    local font_obj = font.font_obj[font_size]

    local default_color = {
        r = 1,
        g = 1,
        b = 1,
    }
     -- variable to implement vertical alignment property
        

    return {
        -- return properties that could be modified or called later
        x = x,
        y = y,
        text = text,
        height = height,
        width = width,
        h_align = h_align,
        v_align = v_align,
        color = color or default_color,
        font_obj = font_obj,
        opacity = opacity,

        getYOffset = function (self)
            local y_offset = 0
            if v_align == "middle" then
                -- offset to reach vertical center
                y_offset = (self.height - self.font_obj:getHeight()) / 2
            elseif v_align == "bottom" then
                y_offset = (self.height - self.font_obj:getHeight())
            end

            return y_offset

        end,


    
        draw = function (self)
            local y_offset = self:getYOffset()

            --todo only do this if screen size was actually updated
            self:updateFontSize()

            -- Scaled px values
            local _x, _y, _width, _ = ScaleObject(self.x, self.y + y_offset, self.width, nil)
            
            
            love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.opacity)
            love.graphics.setFont(self.font_obj)
            love.graphics.printf(self.text, _x, _y, _width, self.h_align)
            
            -- resetting opacity
            love.graphics.setColor(1, 1, 1, 1)
            
            
        end,

        updateFontSize = function (self)
            

            local _font = Font() -- this will not be returned
            local _font_obj = _font.font_obj[font_size]

            self.font_obj = _font_obj
            
        end
        




    }
end

return Text