local love = require "love"
require "globals"


Player = function (self)

    -- initial player stats
    local speed = 0.9 -- determines maximum speed as percentage of area length
    local acceleration = 0.3 -- seconds to topspeed
    local base_speed = 0.2 -- percentage of full speed at which acceleration starts
    local max_speed_px = speed * (1 - (2 * AREA_SIDE_RATIO)) * SCR_WIDTH
    local base_speed_px = max_speed_px * base_speed
    local level = 1 -- level always starts at 1 by default
    local lives = 3
    local score = 0
    local high_score = 0 -- todo fetch actual high score
    local type = "player"

    local outline = STYLE[type].outline
    local line_color = STYLE[type].outline_color
    local line_strength = STYLE[type].outline_strength
    local fill_color = STYLE[type].fill_color
    local fill = STYLE[type].fill
    
    -- initial position
    local x = SCR_WIDTH / 2
    local y = SCR_HEIGHT * (1 - PADDLE_Y_RATIO)
    local width = SCR_WIDTH * PADDLE_WIDTH_RATIO
    local height = SCR_HEIGHT * PADDLE_HEIGHT_RATIO
    local center_offset_x = 0
    local center_offset_y = SCR_HEIGHT * PADDLE_HEIGHT_RATIO / 2
    local type = "player"

    
    return {
        
        line_color = line_color,
        fill_color = fill_color,

        -- player stats
        level = level,
        lives = lives,
        score = score,
        high_score = high_score,

        --#region "POSITION AND DIMENIONS"
        
        x = x,
        y = y,
        width = width,
        height = height,
        center_offset_x = center_offset_x,
        center_offset_y = center_offset_y,
        type = type,
        angle_effect = 0.5, -- weight of angle between ball and player on outgoing trajectory ( 0 = no effect to 1 = angle override)
        
        -- player x position is tracked as center. need to determine left and right edges
        pos = function (self)
            return {
                x_l = self.x - (SCR_WIDTH * PADDLE_WIDTH_RATIO / 2),
                x_r = self.x + (SCR_WIDTH * PADDLE_WIDTH_RATIO / 2),
                y_2 = self.y + (SCR_HEIGHT * PADDLE_HEIGHT_RATIO),
            }
        end,

        --#endregion
        
        
        
        --#region "Movement"
        max_speed_px = max_speed_px,
        base_speed_px = base_speed_px,
        speed_px = base_speed_px, -- starts óut at base, but gets updated

        -- Moves the player/paddle in a specified direction (left or right)
        -- requires direction as string, left and right area as rectangle objects to determine boundaries
        move = function (self, direction, area_l, area_r, dt)
            -- adjustments to min and max because player position is tracked as center
            local min_x = area_l + (self.width / 2)
            local max_x = area_r - (self.width / 2)
            local speed_mod = 1 / love.timer.getFPS()

            if  direction == "left" then
                --must be higher than min_x
                self.x = math.max(self.x - (self.speed_px * speed_mod), min_x)

            elseif direction == "right" then
                -- must be lower than max_x
                self.x = math.min(self.x + (self.speed_px * speed_mod), max_x)

            end
        end,

        accelerate = function (self)
            local acceleration_px = (self.max_speed_px - self.base_speed_px) / acceleration / love.timer.getFPS()
            self.speed_px = math.min(self.speed_px + acceleration_px, self.max_speed_px)
        end,

        decelerate = function (self)
            self.speed_px = self.base_speed_px
        end,


        --#endregion

        updateScore = function (self, points)
            points = points or 0
            self.score = self.score + points
        end,

        updateLives = function(self, bonus)
        -- updates number of player lives, can take negative values
            bonus = bonus or 0
            self.lives = self.lives + bonus
        end,

        updateLevel = function(self, value)
            -- updates player level to the given value, cannot take negative values
            value = value or 1
            if value < 1 then value = 1 end

            
                self.level = value
        end,

        reset = function (self)
            self.lives = lives
            self.score = score
            self.level = level
            self.speed = speed
            self.speed_px = self.speed * SCR_WIDTH
            self:reposition()
        end,

        reposition = function (self)
            -- restore initial position
            self.x = x
            self.y = y
            
        end,

        draw = function (self)
            -- Scaled px values
            -- self
            local _x, _y, _width, _height = ScaleObject(self:pos().x_l, self.y, self.width, self.height)
            local _line_strength = ScalePx(line_strength)

            -- outline
            if outline then
                love.graphics.setColor(self.line_color.r, self.line_color.g, self.line_color.b)
                love.graphics.setLineWidth(_line_strength)
                love.graphics.rectangle("line", _x, _y, _width, _height )
            end

            -- fill
            if fill then
                love.graphics.setColor(self.fill_color.r, self.fill_color.g, self.fill_color.b)
                love.graphics.rectangle("fill", _x, _y, _width, _height )
            end


        end,

        getSaveData = function (self, _slot_id)
           self.id = self.id or _slot_id --todo maybe this should always be _slot_id?
           self.name = self.name or "Untitled Player"

           local save_data = {
            id = self.id,
            name = self.name,
            paddle_x = MathRound(self.x, 0),
            score = self.score,
            level = self.level,
            lives = self.lives,
            ball_id = self.id
           }

           return save_data
        end,

        -- Updates local object properties with data from a loaded save file table
        updateFromSave = function (self, _player_save)
            self.id = _player_save.id
            self.name = _player_save.name
            self.x = _player_save.paddle_x
            self.score = _player_save.score
            self.level = _player_save.level
            self.lives = _player_save.lives
        end


    }
end

return Player


