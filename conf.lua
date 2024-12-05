local love = require "love"

function love.conf(app)
    -- Add copied libraries to path for require
    package.path = package.path .. ".\\lib\\?.lua;.\\lib\\?\\init.lua;"
    
    --window configuration
    app.window.width = 1280
    app.window.height = 720

    app.window.title = "Breakout - Lua"

    app.window.display = 3

    app.window.resizable = true
    
end