require "globals"
local love = require "love"

-- I probably could have done this as variable values in the globals file instead
-- doing it this way as a pseudo OOP style because that's how I learned it so far

Font = function (font_size)

    -- adjust px values according to current screen size
    -- this only works if a new font object is created every time screen is resized

    local font_size_px = {
        h1 = math.floor(ScalePx(60 )),
        h2 = math.floor(ScalePx(50 )),
        h3 = math.floor(ScalePx(40 )),
        h4 = math.floor(ScalePx(30 )),
        h5 = math.floor(ScalePx(20 )),
        p1 = math.floor(ScalePx(14 )),
        p2 = math.floor(ScalePx(10 )),
        x1 = math.floor(ScalePx(100 )),
    }

    local font_obj = {
        h1 = love.graphics.newFont(math.floor(font_size_px.h1)),
        h2 = love.graphics.newFont(math.floor(font_size_px.h2)),
        h3 = love.graphics.newFont(math.floor(font_size_px.h3)),
        h4 = love.graphics.newFont(math.floor(font_size_px.h4)),
        h5 = love.graphics.newFont(math.floor(font_size_px.h5)),
        p1 = love.graphics.newFont(math.floor(font_size_px.p1)),
        p2 = love.graphics.newFont(math.floor(font_size_px.p2)),
        x1 = love.graphics.newFont(math.floor(font_size_px.x1))
    }

    return {
        font_size_px = font_size_px,
        font_obj = font_obj
    }
end

return Font