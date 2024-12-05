local love = require "love"
local Settings = require "settings"
require "lib.sqlite3.sqlite3"

--DEBUG
DEBUGGING = true
DEBUG_LOG = {}






-- Defining unchangeable game constants

-- SCREEN


SCR_DEFAULT_WIDTH = 1280 -- assumed width for later scaling
SCR_DEFAULT_HEIGHT = 720 -- assumed height for later scaling

SCR_HEIGHT = SCR_DEFAULT_HEIGHT -- scr_height used to be dynamic but is easier to change in the draw functions
SCR_WIDTH = SCR_DEFAULT_WIDTH


SCR_SCALE_WIDTH = SCR_WIDTH / SCR_DEFAULT_WIDTH -- scaling for width
SCR_SCALE_HEIGHT = SCR_HEIGHT / SCR_DEFAULT_HEIGHT -- scaling for height

SCR_SCALE_DIAGONAL = 
    (math.sqrt((SCR_WIDTH ^ 2) + (SCR_HEIGHT ^ 2))) -- actual diagonal
    / 
    (math.sqrt((SCR_DEFAULT_WIDTH ^ 2) + (SCR_DEFAULT_HEIGHT ^ 2))) -- assumed diagonal

-- INPUTS
KEY_INPUT_TIMEOUT = 0.2 -- time in seconds for which repeated keypresses are ignore (e.g. for triggering paused screen)
CONTROLS = { --todo assign these elsewhere / fetch from settings file
    -- key assignments during the actual game
    running = {
        paddle_left = "left",
        paddle_right = "right",
        paddle_release = "space",
        pause = "escape"
    },

    paused = {
        unpause = "escape",
        save = "s",
        menu = "m"
    },

    menu = {
        navigate_left = "left",
        navigate_right = "right",
        navigate_up = "up",
        navigate_down = "down",
        confirm = "return",
        back = "escape"
    },

    ended = {
        menu = "escape"
    },

    mode = {
        keyboard = true,
        mouse = false
    }

}

-- LANGUAGE
-- todo implement full language switching support
LANG = {
    default = {
        empty_string = "<empty>"
    }
}

-- PADDLE
PADDLE_WIDTH_RATIO = 0.10 -- ratio of paddle to screen width
PADDLE_HEIGHT_RATIO = 0.02 -- ratio of paddle to scren height
PADDLE_Y_RATIO = 0.10 -- relative y distance from bottom of screen in percent

-- BALL
BALL_RADIUS_RATIO = 0.003


-- GAME AREA
AREA_BOTTOM_RATIO = 0.05 -- relative y distance from bottom of screen
AREA_TOP_RATIO = 0.10
AREA_SIDE_RATIO = 0.15
AREA_DEATH_ZONE_THICKNESS_RATIO = 0.01

-- BRICKS
BRICK_WIDTH_RATIO = 1 / 10 -- second number determines how many bricks per row
BRICK_HEIGHT_RATIO = 1 / 10 -- second number determines how many bricks per column

-- LEVELGRID
GRID_Y_BUFFER_RATIO = 0.05 -- how much distance from top of playing area
GRID_X_BUFFER_RATIO = 0.00 -- how much distance from side of playing area
GRID_AREA_RATIO = 0.5 -- how much of total playing area is covered by the grid

-- SCOREBOARD
BOARD_MARGIN = 0.05

-- SETTINGS
SETTINGS = Settings()
STYLE = SETTINGS:initializeStyle()
SOUND = SETTINGS.sound


-- MATH FUNCTIONS
MathRound = function (number, decimals)
-- requires a number and a number of decimals it should be rounded to
-- returns the rounded number
    number = number or 0
    local diff = 0 -- for deciding to round up or down
    local number_up, number_down = 0,0
    
    decimals = math.max(decimals, 0) or 0 -- catching nil entries or negative decimals
    decimals = math.floor(decimals) -- just in case a float is provided
    
    -- multiply by 10 to move decimal point
    local counter = decimals
    while counter > 0 do
        number = number * 10
        counter = counter - 1
    end

    -- the follwing code surprising works for both positive and negative numbers

   number_up = math.ceil(number)
   number_down = math.floor(number)

   diff = number_up - number

   if diff >= 0.5 then
    number = number_down
   else
    number = number_up
   end

   -- divide by ten to get back to original magnitude
   counter = decimals
   while counter > 0 do
    number = number / 10
    counter = counter - 1
   end

   return number

end

-- This function returns the length of a diagonal
MathDiagonal = function (_width, _height)
    local diagonal = (math.sqrt((_width ^ 2) + (_height ^ 2)))

    return diagonal

end

-- GRAPHICS FUNCTIONS
GetFadedOpacity = function (fade_duration, time_passed, fade_ratio)
-- this function returns an opacity value for objects that fade in and outside
-- default assumption is that roughly 1/3 of time is spent fading in, full opacity, fading out respectively
    
    fade_duration = fade_duration or 3 -- default fade duration in seconds
    fade_ratio = fade_ratio or {0.33, 0.34, 0.33}

    --fade ratio validity check
    -- make sure there are at least 3 entries
    for i = 1, 3 do
        if fade_ratio[i] == nil then fade_ratio[i] = 1 end
    end
    -- make sure sum of entries adds up to 1. entries beyond 3 are ignored
    -- note: this technically can't deal with negative values, but there's only so much I'm gonna account for
    local ratio_sum = fade_ratio[1] + fade_ratio[2] + fade_ratio[3]
    if not (ratio_sum == 1) then
        fade_ratio[1] = fade_ratio[1] / ratio_sum
        fade_ratio[2] = fade_ratio[2] / ratio_sum
        fade_ratio[3] = fade_ratio[3] / ratio_sum
    end

    -- define end points of different stages
    local fade_in = fade_duration * fade_ratio[1]
    local fade_stay = fade_in + (fade_duration * fade_ratio[2])
    local fade_out = fade_stay + (fade_duration * fade_ratio[3]) -- this is basically the same as fade duration, might change structure later

    local opacity = 1

    if time_passed <= fade_in then
        opacity = time_passed / fade_in
    elseif time_passed > fade_stay then
        -- remainig fade out duration is divided by total phase duration. max with 0 to prevent negative opacity values
        opacity = math.max(((fade_out - time_passed) / (fade_duration * fade_ratio[3])), 0)
    else
        opacity = 1 -- redundant but better for clarity
    end

    return opacity
    
end

-- this function shifts rgb values from one toward another by multiplying
-- returns a color table with r, g, b values
-- values should be between 0 and 1
GetColorShift = function (r1, g1, b1, r2, g2, b2)
    local color_output = {
        r = r1 * r2,
        g = g1 * g2,
        b = b1 * b2,
    }

    return color_output


end

-- This function returns a rounded PX value that is adjusted to current screen size
ScalePx = function (_px_value)
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    --[[ local screen_diagonal = MathDiagonal(screen_width, screen_height)
    local default_diagonal = MathDiagonal(SCR_WIDTH, SCR_HEIGHT) ]]
    local width_ratio = screen_width / SCR_WIDTH
    local height_ratio = screen_height / SCR_HEIGHT
    local px_ratio = math.min(width_ratio, height_ratio)

    --local px_ratio = screen_diagonal / default_diagonal

    if (_px_value == nil) or (px_ratio == nil) then
        error("Error: nil value in px scaling\n _px_value: " .. _px_value .. ", px_ratio: " .. px_ratio)
    end

    local output = MathRound(_px_value * px_ratio, 0)
    
    if output < 0 then
        error("Scaling negative pixel value for drawing") -- this should never happen, but just in case
    end

    output = math.max(output, 1) -- prevent rounding pixel values to 0

    return output

end

RepositionPx = function (_x, _y)
    -- prevent nil value exceptions
    if (_x == nil)  or (_y == nil) then
        return _x, _y
    end

    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    
    local screen_ratio = screen_width / screen_height
    local default_ratio = SCR_WIDTH / SCR_HEIGHT
    local stretch_ratio = screen_ratio / default_ratio -- small -> stretched vertically, large -> stretched horizontally
    

    -- recentering x/y coordinates
    if stretch_ratio > 1  then -- if stretched wide, move _x values
    local x_offset = ScalePx(((stretch_ratio - 1) * SCR_WIDTH) / 2) -- additional relative length of screen / 2
        _x = _x + x_offset
    elseif stretch_ratio < 1 then -- if stretched high, move _y values
        local y_offset = ScalePx(((1 - stretch_ratio) * SCR_HEIGHT) / 2) -- additional relative height of screen / 2
        _y = _y + y_offset
    end

    return _x, _y

    
end

-- This function doesn't just adjust object size, but also their position in case of distorted screens
-- width and height can be left as nil for non-rectangles
-- returns x, y, width, height values in that order
ScaleObject = function (_x, _y, _width, _height)

    -- put output into table for looping
    local _output = {
        x = _x,
        y = _y,
        width = _width,
        height = _height,
    }


    -- multiply all non-nil entries by screen size ratio
    for key, value in pairs(_output) do
        if value ~= nil then
            _output[key] = ScalePx(value)
        end
    end

    -- reposition x and y coordinates
    _output.x, _output.y = RepositionPx(_output.x, _output.y)


    return _output.x, _output.y, _output.width, _output.height

    
end



--PHYSICS FUNCTIONS

GetAngle = function (x1, x2, y1, y2)
    --returns angle between two coordinates
    -- first coordinate is at the center
    local y = y1 - y2
    local x = x1 - x2
---@diagnostic disable-next-line: deprecated
    local angle = math.atan2(y, x)

    if angle < 0 then
        angle = (2 * math.pi) + angle
    end
    if angle > (2* math.pi) then
        print("ERROR: Invalid Angle")
        print("Angle: " .. angle)
    end

    -- rounding angle values to avoid certain calculation imprecisions
    return MathRound(angle, 5)
    
end
GetDistance = function (x1 , y1, x2, y2)
    -- returns absolute (positive) distance between two points in pixels

    local distance = 0.0
    
    distance = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)

    return distance

    
end

DoesOverlap = function (object1, object2)
    -- objects need to have the following properties:
    -- x, y, width, height or radius

    -- temp variable for dealing with case of one circle and one rectangle
    local circle = nil
    local rectangle = nil
    local overlap = false

    if object1.radius == nil and object2.radius == nil then
        -- neither object is circular
        if object1.width == nil or object2.width == nil then
            print("Error: at least one object provided is neither circular nor rectangular")
            overlap = false
            return
            
        else
            -- objects are both rectangles
            -- if lower edge obj1 below upper edge of obj2 and upper edge of obj1 above lower edge of obj2
            if (object1.y + object1.height >= object2.y) and (object1.y) <= object2.y + object2.height then

                -- if right edge of obj1 right of left edge of obj2, and left edge of obj1 left of right edge of obj2
                if (object1.x + object1.width >= object2.x) and (object1.x) <= object2.x + object2.width then

                    overlap = true

                end
            end
        end
    elseif object1.width == nil and object2.width == nil then
        -- both objects are circles
        local max_radius = math.max(object1.radius, object2.radius)
        local distance = GetDistance(object1.x, object1.y, object2.x, object2.y)


        if distance <= max_radius then
            -- circles overlap
            overlap = true
        else
            overlap = false
        end

    else
        -- one object is a circle, the other a rectangle
        if object1.radius == nil then
            rectangle = object1
            circle = object2
        elseif object2.radius == nil then
            rectangle = object2
            circle = object1
        end

        -- if center of cirlce + radius is below upper edge of rectangle and center of circle - radius is above lower edge of rectangle
        if (circle.y + circle.radius >= rectangle.y) and (circle.y - circle.radius) <= rectangle.y + rectangle.height then
            -- if center of cirlce + radius is right of left edge of rectangle and center of circle - radius is left of right edge of rectangle
            if (circle.x + circle.radius >= rectangle.x) and (circle.x - circle.radius) <= rectangle.x + rectangle.width then
            overlap = true
            end
            
        end

        
        
    end
    
    return overlap
    
end
IsPointInRectangle = function (x, y, rectangle)
    local overlap = false

    if rectangle == nil then
        rectangle = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
        }
    end

    if (x >= rectangle.x) -- right of rectangle left edge
        and (x <= (rectangle.x + rectangle.width)) -- left of rectangle right edge
        and (y >= rectangle.y) -- below rectangle top edge
        and (y <= (rectangle.y + rectangle.height)) then
        
            overlap = true
    end

    return overlap
    
end

VectorRectangleIntersect = function (rectangle, x1, y1, v_x, v_y, radius)
    -- Takes point + vector and checks for intersect with rectangular object within a vector maginute of 1
    -- returns a table with "bool" (true if intersect), "x" and "y" of intersect, and "ratio" at which vector intersects with rectangle
    -- returns false / nil if invalid rectangle
    radius = radius or 0
    local intersect = {
        ratio = nil,
        x = nil,
        y = nil,
        bool = false
    }

    local log_output = {} -- for debugging log

    

    -- rounding absolute vector magnitude to avoid "near misses" from floating-point imprecision
    
    if (v_x > 0) and (v_x < 0.01) then
        v_x = 0.01
    elseif (v_x < 0) and (v_x > -0.01) then
        v_x = -0.01
    end

    if (v_y > 0) and (v_y < 0.01) then
        v_y = 0.01
    elseif (v_y < 0) and (v_y > -0.01) then
        v_y = -0.01
    end
    

    local x2 = rectangle.x
    local y2 = rectangle.y


    -- need to adjust if rectangle is player, because player x-position is tracked as center
    if  rectangle.type == "player" then
        x2 = x2 - (rectangle.width / 2)
    end
    
    -- check if all conditions for valid rectangle are given
    if (x2 == nil) or (y2 == nil) or (rectangle.width == nil) or (rectangle.height == nil) then
        print("Invalid rectangle object")
        intersect.bool = false
        return intersect -- no collision
    end
    

--[[     if rectangle.type == "border" then
        local threshold = y2 + rectangle.height

        if (y1 + radius + v_y) >= (threshold) then
    
            --print("here")
            
        end
        
    end ]]


    -- Calculate the min and max x and y of the rectangle
    local x_min, x_max = x2, x2 + rectangle.width
    local y_min, y_max = y2, y2 + rectangle.height

    --[[ --DEBUG
    if DEBUGGING and (x1 > x_min) and (x1 < x_max) and (y1 > y_min) and (y1 < y_max) then
        print("stop here")
    end ]]

    -- round numbers to avoid near misses
    -- adjusting rectnagle bounds by radius to allow for simpler collision detection with center instead
    x_min = math.floor(x_min - radius)
    x_max = math.ceil(x_max + radius)
    y_min = math.floor(y_min - radius)
    y_max = math.ceil(y_max + radius)

    -- Declare t multiplier variables for the vector
    local t_x = -1 -- negative 1 chosen as default non-intercept value
    local t_y = -1
    local t_enter = -1
    

    -- Variables 
    local collider = {
        left = false,
        right = false,
        top = false,
        bottom = false,
        
    }
    
    if ((x1) <= x_min) and (v_x > 0) then
        -- Circle is to the left and moving right (toward the rectangle)

        -- only check left edge
        collider.left = true
        collider.right = false
        
    elseif ((x1) >= x_max) and (v_x < 0) then
        -- Circle is to the right and moving left (toward the rectangle)
        
        collider.left = false
        collider.right = true
        
    else
        -- Circle is not moving toward the rectangle horizontally, or is already inside
        collider.left = false
        collider.right = false
    end


    if ((y1) <= y_min) and (v_y > 0) then
        -- Circle is above and moving down (toward the rectangle)
        
        collider.top = true
        collider.bottom = false

    elseif ((y1) >= y_max) and (v_y < 0) then
        -- Circle is below and moving up (toward the rectangle)
        collider.top = false
        collider.bottom = true
    else
        -- Circle is not moving toward the rectangle vertically, or is already inside
        collider.top = false
        collider.bottom = false
    end

    if not (collider.top or collider.bottom or collider.left or collider.right) then
        -- Circle is moving away from rectangle or already inside
        
        
        
        if DEBUGGING then
            log_output = {
                collider = collider, intersect = intersect, x1 = x1, x2 = x2, radius = radius, rectangle =rectangle, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, v_x = v_x, v_y = v_y, t_x = t_x, t_y = t_y, t_enter = t_enter
            }
            RunningLogEntry(log_output, "VectorRectangleIntersect: " .. rectangle.type)
        end
        return intersect -- no collision

    else
        
        -- determine t_y and t_x and multipliers for vector to intersect
        if collider.right then
            -- if collision from right, radius is subtracted from x1 for distance to right edge
            t_x =  (x1 - x_max) / math.abs(v_x)
        elseif collider.left then
            -- if collision from left, radius is added to x1 for distance to left edge
            t_x = (x_min - x1) / math.abs(v_x)
        else
            if (x1 >= (x_min)) and (x1 <= (x_max)) then
                -- circle is inbetween left and right edge already
                if v_x >= 0 then
                    --circle is moving right towards right edge
                    t_x = (x_max - x1) / math.abs(v_x)
                else
                    -- circle is moving left towards left edge
                    t_x = (x1 - x_min) / math.abs(v_x)
                    
                end

            else
                
                -- circle is not inside rectangle and moving away
                t_x = -1 -- -1 acts as dead value

            end
        end
    
        if collider.bottom then
            -- if collision from bottom, radius is subtracted from y1 for distance to bottom edge
            t_y =   ((y1) - y_max) / math.abs(v_y)
        elseif collider.top then
            -- if collision from top, radius is added to y1 for distance to top edge
            t_y = (y_min - (y1)) / math.abs(v_y)
        else

            if ((y1) >= (y_min)) and ((y1) <= (y_max)) then
                -- circle is inbetween top and bottom edge already
                if v_y >= 0 then
                    --circle is moving downwards towards bottom edge
                    t_y = (y_max - (y1)) / math.abs(v_y)
                else
                    -- circle is moving upwards towards top edge
                    t_y = ((y1) - y_min) / math.abs(v_y)
                    
                end

            else
                
                -- circle is not inside rectangle and moving away
                t_y = -1 -- -1 acts as dead value

            end
            
        end
        

        -- if one of the multipliers is negative circle will miss rectangle on current vector
        if (t_x < 0) or (t_y < 0) then
            
            if DEBUGGING then
                log_output = {
                    collider = collider, intersect = intersect, x1 = x1, x2 = x2, radius = radius, rectangle =rectangle, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, v_x = v_x, v_y = v_y, t_x = t_x, t_y = t_y, t_enter = t_enter
                }
                RunningLogEntry(log_output, "VectorRectangleIntersect: " .. rectangle.type)
            end
            return intersect -- no collision

        else
        -- circle would eventually intersect

            if not (collider.left or collider.right) then
                -- if not colliding with outside side edges, t_y is the only valid t_enter option
                local collision_x = x1 + (v_x * t_y)


                -- if x position after apply y collision multiplier is still within rectangle bounds, t_y is valid
                if ((collision_x) >= x_min) and ((collision_x) <= (x_max))  then
                    t_enter = t_y
                else
                    t_enter = -1
                end
            
            elseif not (collider.bottom or collider.top) then 
                -- if not colliding with outside horizontal edges, t_x is the only valid t_enter option
                local collision_y = y1 + (v_y * t_x)

                -- if y position after apply x collision multiplier is still within rectangle bounds, t_y is valid
                if ((collision_y) >= y_min) and ((collision_y) <= (y_max))  then
                    t_enter = t_x
                else
                    t_enter = -1
                end
            else
                -- if collision with at least one vertical and one horizontal edge is possible, the higher value is the correct intersect (because both x and y coordinate need to be reached for actual collision)
                t_enter = math.max(t_x, t_y)
                
            end


            -- Check if distance is greater than one vector length (only care about this case)
            if (t_enter <= 1) and (t_enter >= 0) then
                -- this is used to correct the collision point to not be at the center of the circle
                -- get current travelling vector normalized to magnitude between 0 and 1
                local radius_correction_x = radius
                if v_x < 0 then
                    radius_correction_x = radius * -1
                end

                local radius_correction_y = radius
                if v_y < 0 then
                    radius_correction_y = radius * -1
                end
                
                -- Intersection point (x, y)
                intersect.x = x1 + (v_x * t_enter) + radius_correction_x
                intersect.y = y1 + (v_y * t_enter) + radius_correction_y
                intersect.ratio = t_enter
                intersect.bool = true
                
                if DEBUGGING then
                    log_output = {
                        collider = collider, intersect = intersect, x1 = x1, x2 = x2, radius = radius, rectangle =rectangle, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, v_x = v_x, v_y = v_y, t_x = t_x, t_y = t_y, t_enter = t_enter
                    }
                    RunningLogEntry(log_output, "VectorRectangleIntersect: " .. rectangle.type)
                end
                return intersect
        
            else
                -- distance is greater than 1 vector length
                intersect.bool = false
                
                if DEBUGGING then
                    log_output = {
                        collider = collider, intersect = intersect, x1 = x1, x2 = x2, radius = radius, rectangle =rectangle, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, v_x = v_x, v_y = v_y, t_x = t_x, t_y = t_y, t_enter = t_enter
                    }
                    RunningLogEntry(log_output, "VectorRectangleIntersect: " .. rectangle.type)
                end
                return intersect
        
                
            end

        end
    

    end
    
    -- this area can currently never be reached, but I might change the code later
    if DEBUGGING then
        log_output = {
            collider = collider, intersect = intersect, x1 = x1, x2 = x2, radius = radius, rectangle =rectangle, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, v_x = v_x, v_y = v_y, t_x = t_x, t_y = t_y, t_enter = t_enter
        }
        RunningLogEntry(log_output, "VectorRectangleIntersect: " .. rectangle.type)
    end
    return intersect
    
end

GetCollisionDirection = function (x, y, rectangle, ball)
    -- takes collision coordinates and the rectangle and ball of a collision and determnines whether collision is horizontal or vertical
    -- returns table with "horizontal" and "vertical" boolean values

    local collision = {
        horizontal = false,
        vertical = false
    }

    
    local dist_x -- distance to x value
    local dist_y -- distance to y value

    -- initialize variables for better readability
    local y_top = rectangle.y
    local y_bottom = rectangle.y + rectangle.height
    local x_left = rectangle.x
    local x_right = rectangle.x + rectangle.width

    -- variable used for corner collision fallback. gets ratio of longer side to shorter side
    local fallback_ratio = math.max(rectangle.width, rectangle.height) / math.min(rectangle.width, rectangle.height)
    
    -- get whichever distance is shortest horizontally
    dist_x = math.min(
    GetDistance(x, y, x_left, y), -- distance to left edge ignoring y
    GetDistance(x, y, x_right, y) -- distance to right edge ignoring y
    )

    -- get whichever distance is shortest vertically
    dist_y = math.min(
        GetDistance(x, y, x, y_top), -- distance to top edge ignoring x
        GetDistance(x, y, x, y_bottom) -- distance to bottom edge ignoring x
    )

    -- prevent division by 0
    if dist_x == 0 then dist_x = 0.0001 end
    if dist_y == 0 then dist_y = 0.0001 end

    

    -- if x distance is shorter, collision must be on the side, otherwise on top or bottom (corner cases default to vertical)
    

    if dist_x < dist_y then
        collision.horizontal = true
        collision.vertical = false
    else
        collision.horizontal = false
        collision.vertical = true
    end

    -- fallback to catch near vertical angles
    local long_distance = math.max(dist_x, dist_y)
    local short_distance = math.min(dist_x, dist_y)
    local degree_correction = 2
    local distance_delta = math.abs(dist_x - dist_y)

    if 
            -- if ball angle is close to 90° or 270°, collision is probably vertical, not horizontal
            ((ball.angle_rad <= math.rad(90 + degree_correction)) and (ball.angle_rad >= math.rad(90 - degree_correction)))
            or
            ((ball.angle_rad <= math.rad(270 + degree_correction)) and (ball.angle_rad >= math.rad(270 - degree_correction)))
            then
                print("stop")
    end

    if distance_delta <= ball.radius then
        if 
            -- if ball angle is close to 90° or 270°, collision is probably vertical, not horizontal
            ((ball.angle_rad <= math.rad(90 + degree_correction)) and (ball.angle_rad >= math.rad(90 - degree_correction)))
            or
            ((ball.angle_rad <= math.rad(270 + degree_correction)) and (ball.angle_rad >= math.rad(270 - degree_correction)))
            then

            collision.horizontal = false
            collision.vertical = true
        elseif 
            -- if ball angle is close to 0°, 180, or 360°, collision is probably vertical, not horizontal
            ((ball.angle_rad <= math.rad(0 + degree_correction)) and (ball.angle_rad >= math.rad(0)))
            or
            ((ball.angle_rad <= math.rad(180 + degree_correction)) and (ball.angle_rad >= math.rad(180 - degree_correction)))
            or
            ((ball.angle_rad <= math.rad(360)) and (ball.angle_rad >= math.rad(360 - degree_correction))) 
            then

            collision.horizontal = true
            collision.vertical = false
        end
    end

    return collision

    
    
end



GetVector = function (angle_rad)
-- takes angle argument in radians. returns vector values for x and y
    
    local x = MathRound(math.cos(angle_rad) * (-1), 5)
    local y = MathRound(math.sin(angle_rad) * (-1), 5)

    return x, y
    
end



-- UTILITY FUNCTIONS
--#region Utility Functions
IsString = function (_value)
    return type(_value) == "string"
end

IsNumber = function (_value)
    return type(_value) == "number"
end

-- Checks whether a given string is in ISO 8601 format
IsISODate = function (_string)
    if not IsString(_string) then
        error("Entered parameter is not a string")
    end

    -- note: I googled the below pattern matching
    -- ISO 8601 date-time format: YYYY-MM-DDTHH:MM:SS
    local iso_pattern = "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d$"

    -- Check if the string matches the pattern
    if _string:match(iso_pattern) then
        return true
    else
        return false
    end
end




GetTableN = function (_table)
-- returns number of entries inside a table (does not need to be an array)
-- apparently 'table.getn' used to be able to do this, but was deprecated
    local n = 0

    for i, entry in pairs(_table) do
        n = n + 1
    end

    return n
    
end

SetTableIndex = function (_table)
-- gives tables numerical index values as "index" property / ensures that there are no gaps, duplicates, etc.
-- returns table that includes sorted index values
-- entries without index will be put at the start of the table
-- not necessary for arrays

    if _table == nil then
        return nil
    end

    local table_n = GetTableN(_table)

    local indeces = {}

    
    for key, entry in pairs(_table) do
    -- iterate over entries and make sure all have index values
        local i = 1
        local index_taken = false
        local max_index = 1
        local current_index = entry.index

        -- if no index, assign current iterator
        if entry.index == nil then
            entry.index = i
        
        -- if bigger than number of items in table, set to table_n
        elseif entry.index > table_n then
            entry.index = table_n
        end

        -- check if index value is already taken
        index_taken = TableContainsValue(indeces, entry.index)

        -- if the index is taken. start at the lowest possible index and iterate until a free value is found
        -- this is not "ideal", but simple enough and tables shouldn't be too long
        while index_taken do
            local j = 1
            index_taken = TableContainsValue(indeces, entry.index)

            if not index_taken then
                entry.index = j
            else
                j = j + 1
            end
        end

        -- add the (potentially newly assigned index value to the array tracking indeces)
        table.insert(indeces,entry.index)

        -- assign new value to table that is returned
        _table[key].index = entry.index

    end

    return _table
    
    
end

TableContainsValue = function (table, value)

    for _, current_value in pairs(table) do
        if current_value == value then
            return true
        end
    end
    return false
end

StringToTitleCase = function (str)
-- this function converts the first letter of every word in any string to upper case and returns it
-- I had to google how to do this because lua string patterns are kinda like regex and nobody actually knows that shit by heart
    
    str = str:lower() -- convert to all lower case first

    str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
    return str
end

-- Custom local function to enable pretty print functionality, which isn't natively supported by lunaJSON
-- note: I did not write this code myself
JSONPrettyPrint = function(json_string)
    local level = 0
    local formatted = json_string:gsub("([{}%[%]])", function(char)
        if char == "{" or char == "[" then
            level = level + 1
            return char .. "\n" .. string.rep("  ", level)
        elseif char == "}" or char == "]" then
            level = level - 1
            return "\n" .. string.rep("  ", level) .. char
        else
            return char
        end
    end):gsub('",', '",\n' .. string.rep("  ", level)) -- Adds newline after each key-value pair
    return formatted
end

--#endregion

-- DEBUG FUNCTIONS
--#region Debug Functions
RunningLogEntry = function (data, str_key)
    -- this function is meant to keep a running log in DEBUG_LOG of specific values for the last entry_n iterations
        local log_n = 0 -- number of existing log entries
        local entry_n = 10 -- max number of entries (maybe change this later to be dynamic)
    
        if DEBUG_LOG[str_key] == nil then
            -- if no entries exist for this key, create empty table for indexing
            DEBUG_LOG[str_key] = {}
        else
            log_n = GetTableN(DEBUG_LOG[str_key])
        end
    
        if log_n < entry_n then
            table.insert(DEBUG_LOG[str_key], 1,data)
        else -- if already entry_n entries, remove the last one
            table.remove(DEBUG_LOG[str_key], entry_n)
            table.insert(DEBUG_LOG[str_key], 1,data)
        end
    
        
    end
    
    DebugBall = function (ball)
        print("--DEBUG Ball")
        print("Position: " .. ball.x .. ", ".. ball.y)
        print("Angle: " .. math.deg(ball.angle_rad))
        
    end
    
    DebugCollision = function (x, y, rectangle)
        print("--DEBUG Collision")
        print("Collsion at: " .. x .. ", " .. y)
        print("With Rectangle: ")
        print("x_min: " .. rectangle.x .. ", y_min: " .. rectangle.y)
        print("x_max: " .. rectangle.x + rectangle.width .. ", y_max: " .. rectangle.y + rectangle.height)
        
    end
    --#endregion


