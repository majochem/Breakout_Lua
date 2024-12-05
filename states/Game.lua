require "globals"
local love = require "love"
local Button = require"components.Button"
local Font = require "components.Font"
local Saves = require "components.Saves"



Game = function (player, grid, ball)

    local in_progress = false

    -- This function automaticall creates all necessary properties for screen messages
    -- todo might want to make this a separate module at some point
    local assignMessageProperties = function (
        _msg_obj, -- object that is to receive properties
        msg_text, -- text of main message
        sub_msg_text, -- can be nil if no subtext required
        fade_duration, -- can be nil if no fade
        fade_passed, -- can can be nil if no fade
        fade_opacity_bg, -- determines opacity of screen overlay
        start_opacity -- 0 if fade in, otherwise 1
    )

        if _msg_obj == nil then _msg_obj = {} end -- avoid errors in case of undeclared objects

        local msg_obj = _msg_obj

        -- main msg values
        msg_obj.text = msg_text
        msg_obj.fade_duration = fade_duration
        msg_obj.fade_passed = fade_passed or 0
        msg_obj.fade_opacity_bg = fade_opacity_bg
        msg_obj.opacity = start_opacity
        msg_obj.type = SETTINGS.object_types.screen_msg
        msg_obj.font_size = STYLE[msg_obj.type].font_size
        msg_obj.font_color = STYLE[msg_obj.type].font_color
        msg_obj.width = SCR_WIDTH
        msg_obj.x = 0
        msg_obj.y = SCR_HEIGHT / 3
        msg_obj.type = SETTINGS.object_types.screen_msg
        msg_obj.height = Font().font_size_px[msg_obj.font_size]
        msg_obj.h_align = STYLE[msg_obj.type].h_align
        msg_obj.v_align = STYLE[msg_obj.type].v_align
        
        msg_obj.text_box = Text(msg_obj.x, msg_obj.y, msg_obj.text, msg_obj.width, msg_obj.height, msg_obj.font_size, msg_obj.font_color, msg_obj.h_align, msg_obj.v_align, msg_obj.opacity)

        -- sub msg values
        if not (sub_msg_text == nil) then
            msg_obj.sub_msg = {}
            msg_obj.sub_msg.text = sub_msg_text
            msg_obj.sub_msg.fade_duration = fade_duration
            msg_obj.sub_msg.fade_passed = fade_passed or 0
            msg_obj.sub_msg.fade_opacity_bg = fade_opacity_bg
            msg_obj.sub_msg.opacity = start_opacity
            msg_obj.sub_msg.type = SETTINGS.object_types.screen_sub_msg
            msg_obj.sub_msg.font_size = STYLE[msg_obj.sub_msg.type].font_size
            msg_obj.sub_msg.font_color = STYLE[msg_obj.sub_msg.type].font_color
            msg_obj.sub_msg.width = msg_obj.width
            msg_obj.sub_msg.height = Font().font_size_px[msg_obj.sub_msg.font_size]
            msg_obj.sub_msg.x = msg_obj.x
            msg_obj.sub_msg.y = msg_obj.y + msg_obj.height + msg_obj.sub_msg.height
            msg_obj.sub_msg.h_align = STYLE[msg_obj.sub_msg.type].h_align
            msg_obj.sub_msg.v_align = STYLE[msg_obj.sub_msg.type].v_align

            msg_obj.sub_msg.text_box = Text(msg_obj.sub_msg.x, msg_obj.sub_msg.y, msg_obj.sub_msg.text, msg_obj.sub_msg.width, msg_obj.sub_msg.height, msg_obj.sub_msg.font_size, msg_obj.sub_msg.font_color, msg_obj.sub_msg.h_align, msg_obj.sub_msg.v_align, msg_obj.sub_msg.opacity)
        end

        -- textbox objects
        
        return msg_obj
        
    end

    -- GAME OVER
    -- properties for game over screen
    local game_over = {
        id = "game_over", -- this needs to be equal to the name of the local tbl variable
        text = "Game Over",
        fade_duration = 10, -- total time for which game over text fades in and out
        fade_opacity_bg = 0.8, -- opacity for rest of the game elements during game over
        fade_passed = 0,
        opacity = 0, -- starting opacity is invisible
        sub_text = "Press Escape to return to menu"
    }

    game_over = assignMessageProperties(game_over, game_over.text, game_over.sub_text, game_over.fade_duration, game_over.fade_passed, game_over.fade_opacity_bg, game_over.opacity)
    
    -- PAUSE
    -- properties for pause screen
    local paused = {
        id = "paused", -- this needs to be equal to the name of the local tbl variable
        text = "Paused",
        sub_text = "Press " .. string.upper(CONTROLS.paused.unpause) .. " to unpause"
        .. "\n" .. "Press " .. string.upper(CONTROLS.paused.menu) .. " to return to menu",
        fade_opacity_bg = 0.8, -- opacity for rest of the game elements during game over
        type = "screen_msg",
        opacity = 1, -- starting opacity is invisible
    }
    
    paused = assignMessageProperties(paused,paused.text, paused.sub_text, nil, nil, paused.fade_opacity_bg, paused.opacity )

    -- LEVEL COMPLETE
    -- todo implement showing this
    -- properties for level complete screen
    local level_up = {
        id = "level_up", -- this needs to be equal to the name of the local tbl variable
        text_1 = "Level ", -- combined with player.level later
        text_2 = " Complete!",
        fade_duration = 3, -- total time for which game over text fades in and out
        fade_opacity_bg = 0.8, -- opacity for rest of the game elements during game over
        fade_passed = 0,
        opacity = 0, -- starting opacity is invisible
    }
    level_up.getText = function () -- separate function needed for level_up text as the value changes
        local text_out = level_up.text_1 .. player.level .. "\n" .. level_up.text_2
        return text_out
    end
    level_up.text = level_up.getText()
    
    level_up = assignMessageProperties(level_up, level_up.text,nil,level_up.fade_duration, level_up.fade_passed, level_up.fade_opacity_bg, level_up.opacity)
    
    
    
    -- SOUND
    local music = {
        running = SOUND.sound_groups.game.music.bg_music,
        --todo actually assign separate music for paused
        paused = SOUND.sound_groups.game.music.bg_music,
        ended = SOUND.sound_groups.game.music.game_over,
        menu = SOUND.sound_groups.menu.music.bg_music,
    }

    -- SAVES
    local saves = Saves()
    player.high_score = saves.highscore.high_score


    return {
        state = {
            running = true,
            menu = false,
            paused = false,
            ended = false,
            transition = false,
        },

        saves = saves,

        music = music,

        menu = {}, -- this is later assigned during menu initialization

        -- screen message elements
        paused = paused,
        game_over = game_over,
        level_up = level_up,

        transition = {-- populated later depending on reason for transition
            msg = {},
            time = 0,
            time_passed = 0
        },


        in_progress = in_progress,

        changeGameState = function (self, state)

            self.state.running = state == "running"
            self.state.menu = state == "menu"
            self.state.paused = state == "paused"
            self.state.ended = state == "ended"
            self.state.transition = state == "transition"

            SOUND:playMusic(self.music[state]) -- switch the music corresponding to the state
        end,

        startGame = function (self)


            if not self.in_progress then
                self.in_progress = true
                self.menu.main.menu_entries.resume.visible = true -- not super elegant, but works for now
                self.menu.main.page.columns.left.entries.resume.button.visible = self.in_progress
                
                self:resetGame()
                
            else
                -- do nothing
            end

            self:changeGameState("running")

            
        end,

        resetGame = function (self)
            player:reset()
            ball:reset()
            grid:fillGrid()
        end,

        quitGame = function (self)
            --todo: ask for confirmation if game is running/unsaved
            love.event.quit()
            
        end,

        gameOver = function (self)
            self:checkHighScore()
            player:reset()
            self:changeGameState("ended")
            self.in_progress = false
            self.menu.main.menu_entries.resume.visible = false -- not super elegant, but works for now
        end,
        
        -- checks if player score at time of death should be entered to JSON file
        -- todo actually ask for player name?
        checkHighScore = function (self)
            local score_rank = self.saves.highscore:isHighScore(player.score)

            if score_rank then
                local entry = {}
                -- assign properties
                -- this needs to be updated if JSON structure changes, but it will cause an error
                entry[saves.highscore.datakey.name] = player.name or "Untitled" -- todo fetch from language file
                entry[saves.highscore.datakey.score] = player.score
                entry[saves.highscore.datakey.date] = os.date("!%Y-%m-%dT%H:%M:%S")
                saves.highscore:insertScore(entry, score_rank)
                
            end
        end,




        levelUp = function (self)
            self.level_up.text_box.text = self.level_up.getText()
            self.transition.msg = self.level_up
            self.transition.time = self.level_up.fade_duration
            self.transition.time_passed = 0

            self:changeGameState("transition")

            player:updateLevel(player.level + 1)
            player:reposition()
            ball:reset()
            grid:fillGrid()
        end,

        -- This function draws screen message
        -- requires a msg object as defined within main Game body
        drawScreenMsg = function (self, _msg_obj)

            local id = _msg_obj.id

            -- slightly opaque overlay for the game graphics
            -- covers entire screen
            local bg_color = {}
            bg_color.r, bg_color.g, bg_color.b, bg_color.a = love.graphics.getBackgroundColor()
            love.graphics.setColor(bg_color.r, bg_color.g, bg_color.b, self[id].fade_opacity_bg)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            -- actual "message text box"
            local opacity = _msg_obj.opacity

            if not (self[id].fade_duration == nil) then
                -- if message is meant to fade in, opacity is dynamic
                opacity = GetFadedOpacity(self[id].fade_duration, self[id].fade_passed, nil)
            end
            self[id].text_box.opacity = opacity
            self[id].text_box:draw()

            -- if there is a submessage, draw that too
            if not (_msg_obj.sub_msg == nil) then
                self[id].sub_msg.text_box.opacity = opacity
                self[id].sub_msg.text_box:draw()
            end
            
        end,

        drawGameOverScreen = function (self)

            -- slightly opaque overlay for the game graphics
            -- covers entire screen
            local bg_color = {}
            bg_color.r, bg_color.g, bg_color.b, bg_color.a = love.graphics.getBackgroundColor()
            love.graphics.setColor(bg_color.r, bg_color.g, bg_color.b, self.game_over.fade_opacity_bg)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            -- actual "game over text box"
            local opacity = GetFadedOpacity(self.game_over.fade_duration, self.game_over.fade_passed, nil)
            self.game_over.text_box.opacity = opacity
            self.game_over.text_box:draw()
        end,

        drawPausedScreen = function (self)

            -- slightly opaque overlay for the game graphics
            -- covers entire screen
            local bg_color = {}
            bg_color.r, bg_color.g, bg_color.b, bg_color.a = love.graphics.getBackgroundColor()
            love.graphics.setColor(bg_color.r, bg_color.g, bg_color.b, self.paused.fade_opacity_bg)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            -- actual "paused text box"
            self.paused.text_box.opacity = self.paused.opacity
            self.paused.text_box:draw()
        end,

        -- function returns table with values for the 'save' table
        -- requires _slot_id as an integer initially intended to be 1 to 10
        getGameSave = function(self, _slot_id)
            local save_game = {
                id = _slot_id,
                date_time = os.date("!%Y-%m-%dT%H:%M:%SZ"), -- current sytsem time in ISO 8601 format
                player_id = player.id or _slot_id, -- in case player_id is nil, assume save slot id
            }

            return save_game
        end,

        getSaveData = function (self, _slot_id)
            local save = {
                game = {},
                player = {},
                ball = {},
                grid = {}, -- this also contains grid_row and grid_brick subtables
            }
            -- general game
            save.game = self:getGameSave(_slot_id)

            -- grid
            if grid.id == nil then
                grid:getGridId(_slot_id)
            end
            save.grid = grid:getSaveData()

            -- player
            save.player = player:getSaveData(_slot_id)

            -- ball
            save.ball = ball:getSaveData(_slot_id)

            return save
            
        end,

        -- Saves the current game state into a given slot
        saveGame = function (self, _slot_id)
            -- clean up slot
            self.saves:deleteSaveSlot(_slot_id)

            -- fetch the correctly formatted save file
            local save_data = self:getSaveData(_slot_id)

            -- write it to the db
            self.saves.saveState(save_data)
            
        end,

        -- Loads all data from a save_state at a specific slot and updates game objects
        loadGame = function (self, _slot_id)
            local save_state = self.saves.loadSaveState(_slot_id)

            player:updateFromSave(save_state.player)
            ball:updateFromSave(save_state.ball)
            grid:updateFromSave(save_state.grid)
            
        end


        }

        



end

return Game