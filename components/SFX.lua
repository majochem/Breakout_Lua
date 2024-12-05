
local love = require "love"


function SFX()


    -- for adjustments of base sound level
    local sound_level = {
        music = 0.3,
        effects = 1.0
    }

    -- music transition properties
    local fade_duration = 1 -- in seconds
    local music_queue = {} -- will be populated by functions

    -- menu sounds
    local menu = {
        id = "menu",
        music = {
            bg_music = love.audio.newSource("src/sounds/Menu_bg_music.ogg", "stream"),
        },
        
        effects = {
            hover = love.audio.newSource("src/sounds/Menu_hover.wav", "static"),
            activate = love.audio.newSource("src/sounds/Menu_activate.wav", "static"),
        }
        
    }

    -- ball sounds
    local ball = {
        id = "ball",
        effects = {
            bounce_brick = love.audio.newSource("src/sounds/Ball_bounce_brick.wav", "static"),
            bounce_brick_x = love.audio.newSource("src/sounds/Ball_bounce_brick_x.wav", "static"),
            bounce_paddle = love.audio.newSource("src/sounds/Ball_bounce_paddle.wav", "static"),
            bounce_wall = love.audio.newSource("src/sounds/Ball_bounce_wall.wav", "static"),
            death = love.audio.newSource("src/sounds/Ball_death.wav", "static"),
        }
        
    }

    -- game sounds
    local game = {
        id = "game",
        music = {
            bg_music = love.audio.newSource("src/sounds/Game_bg_music.ogg", "stream"),
            game_over = love.audio.newSource("src/sounds/Game_game_over.ogg", "stream"),
        }
    }

    
    -- for automation or property assignment
    local sound_groups = {
        menu = menu,
        ball = ball,
        game = game
    }
    -- for automation of property assignment
    local sound_categories = {
        music = "music",
        effects = "effects"
    }

    for key, group in pairs(sound_groups) do
        
        -- if group has music, set to looping and adjust volume
        if not (group.music == nil) then
            -- go through all entries in music section and set them to looping and appropriate volume
            for key_2, music_entry in pairs(sound_groups[key].music) do
                sound_groups[key].music[key_2]:setLooping(true)
                sound_groups[key].music[key_2]:setVolume(sound_level.music)    
            end
            
        end

        -- if group has effects adjust volume
        if not (group.effects == nil) then
            -- go through all entries in effects section and set them to not looping and appropriate volume
            for key_2, effect_entry in pairs(sound_groups[key].effects) do
                sound_groups[key].effects[key_2]:setLooping(false)
                sound_groups[key].effects[key_2]:setVolume(sound_level.effects)
            end
        end
    end



    return {
        
        sound_level = sound_level,
        sound_groups = sound_groups,
        fade_duration = fade_duration,
        music_queue = music_queue,

        -- starts background music for the provided group and stops it for all otherwise
        -- music_track should be an actual audio source
        -- music tracks are faded in and out over fade_duration
        playMusic = function (self, music_track)
            for key, group in pairs(self.sound_groups) do
                -- if group exists
                if (not (group.music == nil)) then

                    for key_2, track in pairs(self.sound_groups[key].music) do
                        
                        -- is it the track we want?
                        if (self.sound_groups[key].music[key_2] == music_track) then

                            -- if paused, unpause, otherwise start playing
                            if self.sound_groups[key].music[key_2]:isPlaying() then
                                -- do nothing
                            else
                                SOUND:transition(self.sound_groups[key].music[key_2], "in")
                            end
                        
                        -- if it's not the track that we're looking for, pause it
                        elseif self.sound_groups[key].music[key_2]:isPlaying() then
                            SOUND:transition(self.sound_groups[key].music[key_2], "out")
                        else
                            -- it's not the track we're looking for and it's not playing
                            -- do nothing
                        end
                    end

                end
            end
        end,

        -- plays a given effect
        -- todo implement multiple play modes
        playEffect = function (self, effect)

            effect:play()
            
        end,

        -- adds or removes music tracks from the queue for immediate transition
        -- requires an audio source as a track and "in" or "out" as a string
        transition = function (self, track, in_or_out)
            local queue_id = GetTableN(self.music_queue) + 1
            
            local fade_in = false
            local fade_out = false
            local track_in_queue = false

            in_or_out = in_or_out or "in"

            if in_or_out == "in" then
                fade_in = true
            elseif in_or_out == "out" then
                fade_out = true
            else
                -- fallback is "in"

                print("Error: provided invalid argument to transition. Assuming 'fade in'")

            end

            -- check if track is already in queue
            for key, active_track in pairs(self.music_queue) do
                if active_track.track == track then
                    self.music_queue[key].fade_in = fade_in
                    self.music_queue[key].fade_out = fade_out
                    track_in_queue = true
                end
            end
            
            -- if it isn't add it
            if not track_in_queue then
                self.music_queue[queue_id] = {
                    track = track,
                    fade_in = fade_in,
                    fade_out = fade_out
                }
            end


            
        end,

        -- This function continuously adjusts the volume of music tracks in the queue
        -- it also starts and stops tracks when required
        -- takes in dt as argument from the update function in main
        manageQueue = function (self, dt)
            local volume_adjust = 1
            local new_volume = 1

            for key, music_track in pairs(self.music_queue) do

                -- if no time_passed exists, initialize at 0
                if self.music_queue[key].time_passed == nil then self.music_queue[key].time_passed = 0 end
                self.music_queue[key].time_passed = self.music_queue[key].time_passed + dt

                -- if track is supposed to fade in
                if music_track.fade_in then
                    -- make sure it's playing
                    if not self.music_queue[key].track:isPlaying() then
                        self.music_queue[key].track:play()
                    end

                    
                    if self.music_queue[key].time_passed < self.fade_duration then
                        -- for fade in, the volume is equal to the ratio between time passed and fade_duration
                        volume_adjust = music_track.time_passed / self.fade_duration
                        new_volume = volume_adjust * self.sound_level.music
                        self.music_queue[key].track:setVolume(new_volume)
                    else
                        -- if time is up, fade in is finished
                        self.music_queue[key].fade_in = false
                        
                    end
                elseif music_track.fade_out then
                    if self.music_queue[key].time_passed < self.fade_duration then
                        -- for fade out, the volume is equal to 1 minus the ratio between time passed and fade_duration
                        volume_adjust = 1 - (music_track.time_passed / self.fade_duration)
                        new_volume = volume_adjust * self.sound_level.music
                        self.music_queue[key].track:setVolume(new_volume)
                    else
                        -- if time is up, fade out is finished
                        self.music_queue[key].track:pause()
                        self.music_queue[key].fade_out = false
                        
                    end
                else
                    -- if track is neither fading in, nor out, reset time_passed
                    self.music_queue[key].time_passed = 0

                end
            end
            
        end

    }

end

return SFX