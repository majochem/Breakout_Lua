require "globals"

local love = require "love"
local Font = require "components.Font"
local Text = require "components.Text"

Button = function (func, func_arg, x, y, text, width, height, margin, type)
    
    func = func or function() print("This button has no function attached to it") end
    func_arg = func_arg or {}

    local default_x = 0
    local default_y = 0
    local default_height = 50 * SCR_SCALE_HEIGHT
    local default_width = 100 * SCR_SCALE_WIDTH
    local default_margin = default_height * 0.05 -- assumed 5% margin
    local default_type = "button" -- if no type property given. assume button
    local default_text = "No Text"
    
    -- assign provided values, otherwise assume defaults
    x = x or default_x
    y = y or default_y
    text = text or default_text
    height = height or default_height
    width = width or default_width
    margin = margin or default_margin
    type = type or default_type

    -- fetch style properties
    local font = STYLE[type].font_size
    local h_align = STYLE[type].h_align
    local v_align = STYLE[type].v_align
    
    
    
    -- calling Text() without arguments creates a default text object
    local default_text_obj = Text() 
    local text_obj = nil

    
    if text then -- if text is given, create Text object
        local text_color = STYLE[type].font_color
        text_obj = Text(x, y, text, width, height, font, text_color, h_align, v_align)
        
    end

    text_obj = text_obj or default_text_obj


    return {
        -- assign provided values, otherwise assume defaults
        x = x,
        y = y,
        text_obj = text_obj,
        height = height,
        width = width,
        margin = margin,
        func = func,
        func_arg = func_arg,
        type = type,
        active = false,


    
        draw = function (self)
            -- fetch drawing properties from global STYLE table
            local font_color = STYLE[self.type].font_color
            local fill = STYLE[self.type].fill
            local fill_color = STYLE[self.type].fill_color
            local outline = STYLE[self.type].outline
            local outline_color = STYLE[self.type].outline_color

            -- Scaled px values
            local _x, _y, _width, _height = ScaleObject(self.x, self.y, self.width, self.height)
            local _line_strength = ScalePx(STYLE[self.type].outline_strength)
            
            if self.opacity == nil then
                local opacity = 1
            else
                local opacity = self.opacity
            end

            -- if button is active, change properties to highlighted values
            if self.active then
                -- font highlight works a bit differently, because text is always drawn
                local font_highlight = STYLE[self.type].font_highlight
                if font_highlight then font_color = STYLE[self.type].font_color_highlight end -- color is only changed if highlight property is true

                fill = STYLE[self.type].fill_highlight
                fill_color = STYLE[self.type].fill_color_highlight
                outline = STYLE[self.type].outline_highlight
                outline_color = STYLE[self.type].outline_color_highlight
                _line_strength = ScalePx(STYLE[self.type].outline_strength_highlight)
            end
            
            -- filling
            if fill then
                love.graphics.setColor(fill_color.r, fill_color.g, fill_color.b)
                love.graphics.rectangle("fill", _x, _y, _width, _height)    
            end

            -- outline
            if outline then
                love.graphics.setColor(outline_color.r, outline_color.g, outline_color.b)
                love.graphics.setLineWidth(_line_strength)
                love.graphics.rectangle("line", _x, _y, _width, _height)
            end

            -- text
            self.text_obj.color = font_color
            self.text_obj:draw()
            
        end,

        activate = function (self)
            if self.func_arg == {} then
                func()
            else
                func(func_arg)
            end
        end,

        updateText = function (self, new_text)
            self.text_obj.text = new_text or "no text"
        end
        




    }
end

return Button