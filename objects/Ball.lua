local love = require "love"
require "globals"
--require "objects.Area"
--require "objects.LevelGrid"



Ball = function(player)
    local speed = 0.2
    local speed_increase = 0.005 -- factor by which speed increases per collision with the paddle
    local y_buffer = 0.7 -- factor by which player paddle height is multiplied
    local start_x = SCR_WIDTH / 2 -- start in center
    local start_y = player.y - (player.height * y_buffer)

    local angle_variance = 15                                                -- angle cannot be lower than this or higher than 180 - this
    local start_angle = math.random(90 + angle_variance, 90 - angle_variance) + 180 -- adding 180 because starting angle is downwards
    local start_angle_rad = math.rad(start_angle)

    local color = {
        r = 1,
        g = 1,
        b = 1,
    }

    local visible = true
    local moving = false
    local vulnerable = true

    local updateSpeedPX = function (speed_in)
        local speed_px_output = MathRound(speed_in * math.sqrt((SCR_WIDTH ^ 2) + (SCR_HEIGHT ^ 2)),0) -- speed ratio times diagonal of screen
        return speed_px_output
    end

    -- SOUND
    local effect = {
        bounce = {
            brick = SOUND.sound_groups.ball.effects.bounce_brick,
            brick_x = SOUND.sound_groups.ball.effects.bounce_brick_x,
            wall = SOUND.sound_groups.ball.effects.bounce_wall,
            paddle = SOUND.sound_groups.ball.effects.bounce_paddle,
        },
        death = SOUND.sound_groups.ball.effects.death,
    }




    return {
        y = start_y,
        x = start_x,
        radius = math.floor(BALL_RADIUS_RATIO * SCR_WIDTH),
        speed = speed,
        speed_px = updateSpeedPX(speed),
        color = color,
        angle_rad = start_angle_rad,
        type = "ball",
        visible = visible,
        moving = moving,
        vulnerable = vulnerable,

        -- calculate vector dimensions
        vector = function(self)
            return {
                -- numbers are rounded to avoid floater point imprecision
                x = MathRound(math.cos(self.angle_rad) * (-1), 5),
                y = MathRound(math.sin(self.angle_rad) * (-1), 5),
            }
        end,

        launch = function (self)
            self.moving = true
        end,


        reset = function (self)
            self.moving = false
            self.x = start_x
            self.y = start_y
            self.angle_rad = start_angle_rad
            self.speed = speed
            self.speed_px = updateSpeedPX(speed)
        end,

        
        increaseSpeedOnCollision = function (self)
            self.speed = MathRound(self.speed * (1 + speed_increase), 6)
            self.speed_px = updateSpeedPX(self.speed)
        end,

        
        
        
        -- horizontal collision means hit from left or right, so that the angle needs to be mirrored along the y-axis
        horizontalCollision = function(self)

            local v_x, v_y = self:vector().x, self:vector().y

            --mirror x vector
            v_x = v_x * -1
            -- get angle of new vector
            self.angle_rad = GetAngle(0, v_x, 0, v_y)



            -- OLD FUNCTION BELOW
--[[             -- upper right quadrant of cricle
            if (self.angle_rad > 0.5 * math.pi) and (self.angle_rad <= 1.0 * math.pi) then
                self.angle_rad = math.pi - self.angle_rad
                
                -- lower left quadrant of circle
            elseif (self.angle_rad > 1.5 * math.pi) and (self.angle_rad <= 2.0 * math.pi) then
                self.angle_rad = (2 * math.pi - self.angle_rad) + math.pi
                
                -- upper left quadrant of circle
            elseif (self.angle_rad >= 0.0 * math.pi) and (self.angle_rad < 0.5 * math.pi) then
                self.angle_rad = math.pi - self.angle_rad
                
                -- upper left quadrant of circle
            elseif (self.angle_rad > 1.0 * math.pi) and (self.angle_rad < 1.5 * math.pi) then
                self.angle_rad = (2 * math.pi - self.angle_rad) + math.pi
            else
                -- only other possibilities are == 0.5 pi or 1.5 pi, which have no effect becaue they're exctly vertical
                -- so, do nothing
            end ]]
        end,
        
        -- vertical collision means hit from above or below, so that the angle needs to be mirrored along the x-axis
        verticalCollision = function(self)

            -- get vector values
            local v_x, v_y = self:vector().x, self:vector().y

            -- reverse y vector
            v_y = v_y * -1

            -- update angle with new vector
            self.angle_rad = GetAngle(0, v_x, 0, v_y)



            --[[ -- upper half of cricle
            if (self.angle_rad > (0.0 * math.pi)) and (self.angle_rad < (1.0 * math.pi)) then
                self.angle_rad = (2 * math.pi) - self.angle_rad
                
                -- lower half of circle
            elseif (self.angle_rad > (1.0 * math.pi)) and (self.angle_rad < (2.0 * math.pi)) then
                self.angle_rad = (2 * math.pi) - self.angle_rad
            else
                -- only other possibilities are == 0, pi, or 2 pi, which have no effect becaue they're exctly horizontal
                -- so, do nothing
                print("ERROR: invalid vertical collision")
                print("Angle: " .. self.angle_rad)
            end ]]
        end,
        
        playerCollision = function (self, player)
            local x1 = player.x -- player x is already centered
            local y1 = player.y + player.center_offset_y -- y coordinate neeeds to be adjusted
            
            local x2 = self.x
            local y2 = self.y

            local angel_to_player = GetAngle(x1, x2, y1, y2)
            local angle_original = self.angle_rad -- this says "original" but happens after vertical/horizontal collision is already performed"

            -- calculate new angle, taking into account the effect of the player (paddle) on the ball's angle
            local angle_new = (angle_original * (1 - player.angle_effect)) + (angel_to_player * player.angle_effect)
            
            self.angle_rad = angle_new
            self:increaseSpeedOnCollision()
            
            
        end,
        
        checkPlayerCollision = function(self, player, d_speed)
            
            -- initialize collision.bool as false no need to assign other values
            local collision = {
                bool = false
            }
            
            -- only do more complicated checks if ball is at least close to paddle y values
            if self.y > (player.y - player.height - self.speed_px) then
                local v_x = self:vector().x * d_speed
                local v_y = self:vector().y * d_speed
                
                -- ball collide with paddle if full vector is applied?
                collision = VectorRectangleIntersect(player, self.x, self.y, v_x, v_y, self.radius)

                if collision.bool then

                    
                    
                    -- move ball to position of collision
                    self.x = self.x + (v_x * collision.ratio)
                    self.y = self.y + (v_y * collision.ratio)
                    
                    -- perform normal collision first
                    local direction = GetCollisionDirection(collision.x, collision.y, player, self)
                    if direction.horizontal then
                        self:horizontalCollision()
                    else
                        self:verticalCollision()
                    end

                    -- playerCollision will only adjust the angle if player.angel_effect is >0
                    self:playerCollision(player)

                    -- play collision sound
                    SOUND:playEffect(effect.bounce.paddle)

                

                end

            end

            return collision
        end,
        
        checkAreaCollision = function(self, area, d_speed)
            -- checks if there is a collision between ball and area at remaining speed
            -- returns collision table and ratio of vector at which intersection occured
            
            local collision = {
                bool = false,
                --horizontal = false,
                --vertical = false,
                ratio = 0
            
            }

            local v_x = self:vector().x * d_speed 
            local v_y = self:vector().y * d_speed
            local new_x = (self.x + v_x)
            local new_y = (self.y + v_y)
            local border = {}
            local fallback_buffer = 2 -- this is used as a fallback for faulty collision detection. if the ball goes more than this amount of pixels beyond the border it is force teleported back (not elegant, but should work)

            
            
            
            
            -- check collision with area borders

            -- new position of ball including radius is below of area boundary (rounded to avoid near misses)
            if (math.ceil(new_y + self.radius) >= (area.y + area.height)) then
                border = area:getBorder("bottom")
                collision = VectorRectangleIntersect(border, self.x, self.y, v_x, v_y, self.radius)
                if collision.bool then
                    -- move until point of intersection
                    self.x = self.x + (v_x * collision.ratio)
                    self.y = self.y + (v_y * collision.ratio)
                    self:verticalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound
                    return collision

                -- if ball somehow ended up outside the border already
                elseif self.y > area.y + area.height + fallback_buffer then
                    -- force collision values
                    collision.bool = true 
                    collision.ratio = 1
                    collision.x = self.x
                    collision.y = area.y + area.height

                    -- teleport and adjust angle
                    self.y = area.y + area.height - fallback_buffer - self.radius
                    self:verticalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound
                    return collision
                end
            end
            
            -- new new position of ball including radius is above of area boundary
            if (math.floor(new_y - self.radius) <= (area.y)) then
                border = area:getBorder("top")
                collision = VectorRectangleIntersect(border, self.x, self.y, v_x, v_y, self.radius)
                if collision.bool then
                    -- move until point of intersection
                    self.x = self.x + (v_x * collision.ratio)
                    self.y = self.y + (v_y * collision.ratio)
                    self:verticalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound
                    return collision
                
                -- if ball somehow ended up outside the border already
                elseif self.y < area.y - fallback_buffer then
                    -- force collision values
                    collision.bool = true 
                    collision.ratio = 1
                    collision.x = self.x
                    collision.y = area.y

                    -- teleport and adjust angle
                    self.y = area.y + fallback_buffer + self.radius
                    self:verticalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound

                    return collision
                end
            end
            
            -- new new position of ball including radius is right of area boundary
            if (math.ceil(new_x + self.radius) >= (area.x + area.width)) then 
                border = area:getBorder("right")
                collision = VectorRectangleIntersect(border, self.x, self.y, v_x, v_y, self.radius)
                if collision.bool then
                    -- move until point of intersection
                    self.x = self.x + (v_x * collision.ratio)
                    self.y = self.y + (v_y * collision.ratio)
                    self:horizontalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound
                    return collision
                
                -- if ball somehow ended up outside the border already
                elseif self.x > area.x + area.width + fallback_buffer then
                    -- force collision values
                    collision.bool = true
                    collision.ratio = 1
                    collision.x = area.x + area.width
                    collision.y = self.y

                    -- teleport and adjust angle
                    self.x = area.x + area.width - fallback_buffer - self.radius
                    self:horizontalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound

                    return collision
                end
            end

            -- new new position of ball including radius is left of area boundary
            if (math.floor(new_x - self.radius) <= area.x) then
                border = area:getBorder("left")
                collision = VectorRectangleIntersect(border, self.x, self.y, v_x, v_y, self.radius)
                if collision.bool then
                    -- move until point of intersection
                    self.x = self.x + (v_x * collision.ratio)
                    self.y = self.y + (v_y * collision.ratio)
                    self:horizontalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound
                    return collision
                -- if ball somehow ended up outside the border already
                elseif self.x < area.x - fallback_buffer then
                    -- force collision values
                    collision.bool = true
                    collision.ratio = 1
                    collision.x = area.x
                    collision.y = self.y

                    -- teleport and adjust angle
                    self.x = area.x + fallback_buffer + self.radius
                    self:horizontalCollision()
                    SOUND:playEffect(effect.bounce.wall) -- play collision sound

                    return collision

                end
            end
            
            return collision
        end,
        
        
        checkBrickCollision = function (self, grid, d_speed, player)
        -- note: for the brick collisions, sound is handled inside the Brick hitResponse method
            -- speed adjusted vector length
            local v_x = self:vector().x * d_speed 
            local v_y = self:vector().y * d_speed


            -- initialize collision table with non-collision values
            local collision = {
                bool = false,
                ratio = 0
            }
            
            
            -- Go through every brick in level grid. row by row, column by column
            -- for i, row in ipairs(grid.grid)  do
            for i = 1, grid.max_row do -- cannot utilize ipairs loop because it aborts at first nil value
                
                -- if row is empty, skip
                if grid.grid[i] == nil then
                    goto next_row -- using this because Lua doesn't have break loop keyword
                end

                --for j, brick in ipairs (row) do
                for j = 1, grid.max_col do
                    local brick = grid.grid[i][j]

                    -- if brick exists, do collision detection
                    if not (brick == nil) then

                        collision = VectorRectangleIntersect(brick,self.x, self.y, v_x, v_y, self.radius)

                        if collision.bool then

                            --DebugBall(self)
                            --DebugCollision(collision.x, collision.y, brick)

                            local direction = GetCollisionDirection(collision.x, collision.y, brick, self)
                            
                            if direction.vertical then
                                
                                -- move ball to collision point
                                self.x = self.x + (v_x * collision.ratio)
                                self.y = self.y + (v_y * collision.ratio)
                                self:verticalCollision()

                            elseif direction.horizontal then
                               
                                -- move ball to collision point
                                self.x = self.x + (v_x * collision.ratio)
                                self.y = self.y + (v_y * collision.ratio)
                                self:horizontalCollision()
                            else

                                print("what?")
                                DebugBall(self)
                                print("Ball coordinates:" .. self.x .. ", " .. self.y)
                                print("Collision coordinates: " .. collision.x .. ", " .. collision.y)
                                print("Brick coordinates:" .. brick.x .. ", " .. brick.y)
                                

                            end
                            
                            --trigger hitResponse
                            local destroy, points = brick:hitResponse()
                            player:updateScore(points) -- award points
                            if destroy then
                                -- set hit brick from grid table to nil
                                grid.grid[i][j] = nil
                                
                            end
                            return collision


                        end
                        
                        
                    end
                    
                end
                ::next_row::
            end
            return collision
        end,

        checkForDeath = function (self, area)

            local overlap = false
            overlap = IsPointInRectangle(self.x, self.y, area.death_zone)
            if overlap then
                SOUND:playEffect(effect.death)
                self:reset()
                player:updateLives(-1)
            end
        end,
        
        move = function(self, player, area, grid, delta_t)
            if not self.moving then
                return
            end
            

            local v_x = self:vector().x
            local v_y = self:vector().y
            local temp_speed = self.speed_px / love.timer.getFPS()
            --note: switching from dt to FPS due to interference when debugging
            --local temp_speed = self.speed_px * delta_t

            
            local player_collision = {}
            local area_collision = {}
            local brick_collision = {}

            local run_counter = 0

            

            
            local run_collisions = true

            while run_collisions and (run_counter < 1)   do

                player_collision = self:checkPlayerCollision(player, temp_speed)

                if player_collision.bool then
                    -- if already collided with player lower remaining travel distance by remaining vector magnitude
                    temp_speed = temp_speed * (1 - player_collision.ratio)
                end

                area_collision = self:checkAreaCollision(area, temp_speed)

                if area_collision.bool then
                    -- if already collided with area lower remaining travel distance by remaining vector magnitude
                    temp_speed = temp_speed * (1 - area_collision.ratio)
                end

                brick_collision = self:checkBrickCollision(grid, temp_speed, player)

                if brick_collision.bool then
                    -- if already collided with brick lower remaining travel distance by remaining vector magnitude
                    temp_speed = temp_speed * (1 - brick_collision.ratio)
                end

                run_counter = run_counter + 1
                -- make sure loop keeps running until no more collisions area detected [mechanic is not currently in use because it was causing issues]
                if (player_collision.bool or area_collision.bool or brick_collision.bool) and (temp_speed > 1) then
                    run_collisions = true
                else
                    run_collisions = false
                end

            end

            if self.vulnerable then
                self:checkForDeath(area)
            end

            -- get updated ball vector and apply remaining speed multiplier for final position
            v_x = self:vector().x
            v_y = self:vector().y
            self.x = self.x + ( v_x * temp_speed )
            self.y = self.y + ( v_y * temp_speed )


            
        end,
        draw = function(self)
            -- todo dynamic color assignment
            if self.visible then

                -- Scaled px values
                local _x, _y = ScaleObject(self.x, self.y, nil, nil)
                --[[ local _x = ScalePx(self.x)
                local _y = ScalePx(self.y) ]]
                local _radius = ScalePx(self.radius)
                
                
                love.graphics.setColor(self.color.r, self.color.g, self.color.b)
                
                love.graphics.circle("fill", _x, _y, _radius)
                
                love.graphics.setColor(1, 1, 1)
            end

        end,

        getSaveData = function (self, _slot_id)
            self.id = player.id or _slot_id --todo currently id is tied to player, which makes it a bit obsolete. maybe change

            local save_data = {
                id = self.id,
                x = MathRound(self.x,0),
                y = MathRound(self.y, 0),
                angle_rad = self.angle_rad,
                speed = MathRound(self.speed, 6)
            }

            return save_data
        end,

        -- Updates local object properties with data from a loaded save file table
        updateFromSave = function (self, _ball_save)
            self.id = _ball_save.id
            self.x = _ball_save.x
            self.y = _ball_save.y
            self.speed = _ball_save.speed
            self.angle_rad = _ball_save.angle_rad
        end
        
    }
end

return Ball
