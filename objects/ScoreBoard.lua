require "globals"
local love = require "love"
local Button = require"components.Button"

ScoreBoard = function (player, game)

    local remaining_edge = SCR_WIDTH * AREA_SIDE_RATIO
    local margin_ratio = 0.05 -- represents margin in percent
    local margin_x = margin_ratio * remaining_edge
    local margin_y = (margin_ratio * 2) * SCR_HEIGHT -- I want the vertical margin to be bigger, so I multiplied by 2 here
    local v_align = "top" -- todo possibly integrate alignments into style
    local h_align = "left"


    -- define visual properties of various elements
    local left_frame = {
        x = margin_x,
        y = margin_y,
        width = remaining_edge - (margin_x * 2),
        height = SCR_HEIGHT - (margin_y * 2),

        elements = {}
    }

    local right_frame = {
        x = (SCR_WIDTH - margin_x) - (remaining_edge - (margin_x * 2)), -- need to move to the left by width, but can't self-reference width here, so the math looks a bit complicated
        y = margin_y,
        width = remaining_edge - (margin_x * 2),
        height = SCR_HEIGHT - (margin_y * 2),

        elements = {}
    }

    local level_display = {
        frame = "left",
        x = left_frame.x,
        y = left_frame.y,
        width = left_frame.width,
        height = left_frame.height * 0.1,
        text = "Level: " .. player.level,
        type = "stat_display",
    }

    local lives_display = {
        frame = "left",
        x = left_frame.x,
        y = level_display.y + level_display.height + margin_y,
        width = left_frame.width,
        height = left_frame.height * 0.25,
        text = "Lives:\n" .. player.lives,
        type = "stat_display"
    }

    local high_score_display = {
        frame = "right",
        x = right_frame.x,
        y = right_frame.y,
        width = right_frame.width,
        height = right_frame.height * 0.1,
        text = "High Score:\n" .. player.high_score, --todo these text pieces should really be dynamic
        type = "stat_display"
    }

    local score_display = {
        frame = "right",
        x = right_frame.x,
        y = high_score_display.y + high_score_display.height + margin_y,
        width = right_frame.width,
        height = right_frame.height * 0.1,
        text = "Score:\n" .. player.score,
        type = "stat_display"

    }

    
    

    return {
        left_frame = left_frame,
        right_frame = right_frame,
        level_display = level_display,
        lives_display = lives_display,
        score_display = score_display,
        high_score_display = high_score_display,

        init = function (self)
            -- Assign buttons
            -- left frame:
            left_frame.elements.level = Button(nil, nil, self.level_display.x, self.level_display.y, self.level_display.text, self.level_display.width, self.level_display.height,nil, self.level_display.type)
            left_frame.elements.lives = Button(nil, nil, self.lives_display.x, self.lives_display.y, self.lives_display.text, self.lives_display.width, self.lives_display.height,nil, self.lives_display.type)

            -- right frame:
            right_frame.elements.high_score = Button(nil, nil, self.high_score_display.x, self.high_score_display.y, self.high_score_display.text, self.high_score_display.width, self.high_score_display.height,nil, self.high_score_display.type)
            right_frame.elements.score = Button(nil, nil, self.score_display.x, self.score_display.y, self.score_display.text, self.score_display.width, self.score_display.height,nil, self.score_display.type)

        end,

        update = function (self)
            self:updateScore()
            self:updateHighScore()
            self:updateLives()
            self:updateLevel()
        end,
        
        updateScore = function (self)
            right_frame.elements.score:updateText("Score:\n" .. player.score)
        end,

        updateHighScore = function (self)
            -- update high score if current score is higher
            if player.score > player.high_score then
                player.high_score = player.score -- probably should be doing this inside Player.lua, but the logic works well here for now
                right_frame.elements.high_score:updateText("High Score:\n" .. player.high_score)
            end
        end,

        updateLives = function (self)
            left_frame.elements.lives:updateText("Lives:\n" .. player.lives)
        end,

        updateLevel = function (self)
            left_frame.elements.level:updateText("Level: " .. player.level)
        end,
        

        draw = function (self)

            -- left frame
            for _, element in pairs(self.left_frame.elements) do
                element:draw()
            end

            -- right frame
            for _, element in pairs(self.right_frame.elements) do
                element:draw()
            end
            
        end

    }
end

return ScoreBoard