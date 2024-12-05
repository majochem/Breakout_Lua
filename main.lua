---@diagnostic disable: lowercase-global
-- Add copied libraries to path for require
package.path = package.path .. ".\\lib\\?.lua;.\\lib\\?\\init.lua;"

--additional code required for debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    package.path = package.path ..
    "C:\\Users\\majoc\\.vscode\\extensions\\tomblind.local-lua-debugger-vscode-0.3.3\\debugger\\?.lua;"
    require("lldebugger").start()
end

require "globals"
local love = require "love"
local Player = require "objects.Player"
local Ball = require "objects.Ball"
local Area = require "objects.Area"
local LevelGrid = require "objects.LevelGrid"
local Button = require "components.Button"
local Page = require "components.Page"
local Game = require "states.Game"
local Menu = require "states.Menu"
local ScoreBoard = require "objects.ScoreBoard"

-- DEBUGGING
local key_pause = 0


-- libraries
local lunajson = require "lunajson"

math.randomseed(os.time())

--#region "instancing game objects"
local player = Player()
local ball = Ball(player)
local area = Area()
local grid = LevelGrid(player)
local page = Page() -- probably not needed
local game = Game(player, grid, ball)
local menu = Menu(game, player)
local score_board = ScoreBoard(player, game)

--#endregion



-- Load assets and initialize the game
function love.load()

    if DEBUGGING then
        debug_text = Text(0, SCR_HEIGHT * 0.8, "no text", 200, 100, "p1", nil, nil, nil, nil)
    end
    

    love.graphics.setBackgroundColor(0.2, 0.2, 0.2) -- todo fetch from styles
    

    area:initDeathZone()
    grid:fillGrid()

    menu:init()
    --[[ menu:initMain()
    menu:initSettings() ]]

    score_board:init()

    --menu:changeMenuPage("settings")

    game:changeGameState("menu")

    
end

-- Update game logic, called every frame
function love.update(dt)

    
    key_pause = key_pause + dt -- used to avoid double triggering of keypresses

    if DEBUGGING then
        
        if love.keyboard.isDown(",") then
            menu:changeMenuPage("main")
        elseif love.keyboard.isDown(".") then
            menu:changeMenuPage("settings")
        elseif love.keyboard.isDown("-") then
            game:changeGameState("running")
        elseif love.keyboard.isDown("m") then
            game:changeGameState("menu")
        elseif love.keyboard.isDown("+") then
            -- don't want to trigger this more than once per second
            if key_pause > KEY_INPUT_TIMEOUT then
                game:levelUp()
                key_pause = 0
                
            end
        -- dummy save to slot 1
        elseif love.keyboard.isDown("1") then
            -- don't want to trigger this more than once per second
            if key_pause > KEY_INPUT_TIMEOUT then
                game:saveGame(1)
                key_pause = 0
                
            end
        -- dummy load from slot 1
        elseif love.keyboard.isDown("2") then
            -- don't want to trigger this more than once per second
            if key_pause > KEY_INPUT_TIMEOUT then
                game:loadGame(1)
                key_pause = 0
                
            end
        elseif love.keyboard.isDown("b") then
            if key_pause > KEY_INPUT_TIMEOUT then
                ball:reset()
                key_pause = 0
            end

        elseif love.keyboard.isDown("p") then
            if key_pause > KEY_INPUT_TIMEOUT then
                game.saves.highscore:debugPrintAllEntries()
                key_pause = 0
            end

        end

        debug_text.text = "FPS: " .. tostring(love.timer.getFPS())
        
            --[[ "Nav Index: " .. tostring(game.menu[game.menu.active_page].page.nav_values.active.x) .. ", " .. 
            tostring(game.menu[game.menu.active_page].page.nav_values.active.y) ]]
    end

    -- SOUND
    SOUND:manageQueue(dt)

    if game.state.running then
        --#region "Running"
        --#region "Keypress check"
        if love.keyboard.isDown(CONTROLS.running.paddle_right) then
            player:accelerate()
            player:move("right", area.x,area.x + area.width,dt)
            
        elseif love.keyboard.isDown(CONTROLS.running.paddle_left) then
            player:accelerate()
            player:move("left", area.x,area.x + area.width,dt)
        else
            player:decelerate()

        end
    
        if love.keyboard.isDown("escape") then
            if key_pause > KEY_INPUT_TIMEOUT then
                game:changeGameState("paused")
                key_pause = 0
            end
        end

        if not ball.moving then
            
            if love.keyboard.isDown(CONTROLS.running.paddle_release) then
                ball:launch()
            end
        end
        --#endregion "Keypress check"

        --#region "Ball movement"

        
        ball:move(player, area, grid, dt)
        
        --#endregion "Ball movement"
        
        --#region Score, Levels and Lives
        score_board:update()
        if player.lives <= 0 then
            game:gameOver()
        end

        if grid:isEmpty() then
            game:levelUp()
        end


        --#endregion "Running"

    --#region "Ended" / Gameover
    elseif game.state.ended then
        if game.game_over.fade_passed <= game.game_over.fade_duration then
            game.game_over.fade_passed = game.game_over.fade_passed + dt
            if love.keyboard.isDown(CONTROLS.ended.menu) and key_pause > KEY_INPUT_TIMEOUT then
                game.game_over.fade_passed = 0
                key_pause = 0
                game:changeGameState("menu")
            end
        else
            game.game_over.fade_passed = 0
            game:changeGameState("menu")
        end

    --#endregion Game over
    
    --#region Paused
    elseif game.state.paused then
        
        if love.keyboard.isDown(CONTROLS.paused.unpause) then
            if key_pause > KEY_INPUT_TIMEOUT then
                game:changeGameState("running")
                key_pause = 0
            end
        elseif love.keyboard.isDown(CONTROLS.paused.menu) then
            if key_pause > KEY_INPUT_TIMEOUT then
                
                game:changeGameState("menu")
                key_pause = 0
            end
        end
    --#endregion Pause

    --#region transition
    elseif game.state.transition then
        game.transition.time_passed = game.transition.time_passed + dt
        game[game.transition.msg.id].fade_passed = game.transition.time_passed -- align time_passed value with appropraite msg object
        
        if game.transition.time_passed > game.transition.time then
            game:changeGameState("running")
            game.transition.time_passed = 0
            game[game.transition.msg.id].fade_passed = 0
        end
    
    --#endregion
    --#region "Menu"
    elseif game.state.menu then

        -- if keyboard mode and lockout timer has passed
        if key_pause > KEY_INPUT_TIMEOUT and CONTROLS.mode.keyboard then
            local relevant_key, key = game.menu:getMenuKeyisdown()
                if relevant_key then
                    key_pause = 0
                    game.menu:navigateKeyboard(key)
                    
                end
        
        elseif CONTROLS.mode.mouse then
            game.menu:navigateMouse()

        end

    end
    --#endregion "Menu"


end

    

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        ball.angle_rad = GetAngle(ball.x, x, ball.y, y)
        
    end
end

--#region Draw
function love.draw()

    -- bundling of function packages (maybe not smart to have this inside "draw" as it will be constantly overwritten)
    local drawRunningElements = function ()
                -- order of drawing actually matters because of "overdrawing"
                grid:draw()
                player:draw()
                ball:draw()
                score_board:draw()
                area:draw()
    end

    if DEBUGGING then
        debug_text.text = "DEBUG MODE: TRUE\n".. "Debug text:\n" .. debug_text.text
        debug_text:draw()
    end

    if game.state.running then
        
        drawRunningElements()

    elseif game.state.ended then
        drawRunningElements() -- running elements still drawn, but will be covered

        game:drawScreenMsg(game.game_over)
    elseif game.state.paused then
        drawRunningElements() -- running elements still drawn, but will be covered
        game:drawScreenMsg(game.paused)

    elseif game.state.transition then
        drawRunningElements() -- running elements still drawn, but will be covered
        game:drawScreenMsg(game.transition.msg)
        
    elseif game.state.menu then
        menu:draw()
        
    end

    

end

--endregion Draw
