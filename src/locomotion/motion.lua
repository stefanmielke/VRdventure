local config = require 'config'

local motion = {
    pose = lovr.math.newMat4(), -- Transformation in VR initialized to origin (0,0,0) looking down -Z

    -- Snap motion parameters
    snap_turn_angle = 2 * math.pi / 12,
    dash_distance = 1.5,
    thumbstick_cooldown_time_walk = 0.3,
    thumbstick_cooldown_walk = 0,
    thumbstick_cooldown_time_turn = 0.3,
    thumbstick_cooldown_turn = 0,

    -- Smooth motion parameters
    turning_speed = 2 * math.pi * 1 / 6,
    walking_speed = 4
}

function motion.reset(initial_pose)
    motion.pose:set(initial_pose or lovr.math.Mat4())
end

local function smooth_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        local direction = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
        direction.y = 0

        -- Smooth strafe movement
        if math.abs(x) > config.input.thumbstick_deadzone then
            local strafeVector = quat(-math.pi / 2, 0, 1, 0):mul(vec3(direction))
            motion.pose:translate(strafeVector * x * motion.walking_speed * dt)
        end

        -- Smooth Forward/backward movement
        if math.abs(y) > config.input.thumbstick_deadzone then
            motion.pose:translate(direction * y * motion.walking_speed * dt)
        end
    end
end

local function smooth_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')

        -- Smooth horizontal turning
        if math.abs(x) > config.input.thumbstick_deadzone then
            motion.pose:rotate(-x * motion.turning_speed * dt, 0, 1, 0)
        end
    end
end

local function snap_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        if math.abs(y) > config.input.thumbstick_deadzone and motion.thumbstick_cooldown_walk < 0 then
            local move_vector = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
            if not motion.flying then
                move_vector.y = 0
            end
            move_vector:mul(y / math.abs(y) * motion.dash_distance)
            motion.pose:translate(move_vector)
            motion.thumbstick_cooldown_walk = motion.thumbstick_cooldown_time_walk
        end
    end

    motion.thumbstick_cooldown_walk = motion.thumbstick_cooldown_walk - dt
end

local function snap_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')
        if math.abs(x) > config.input.thumbstick_deadzone and motion.thumbstick_cooldown_turn < 0 then
            local angle = -x / math.abs(x) * motion.snap_turn_angle
            motion.pose:rotate(angle, 0, 1, 0)
            motion.thumbstick_cooldown_turn = motion.thumbstick_cooldown_time_turn
        end
    end

    motion.thumbstick_cooldown_turn = motion.thumbstick_cooldown_turn - dt
end

function motion.update(dt)
    if config.locomotion.smooth_walk then
        smooth_walk(dt)
    else
        snap_walk(dt)
    end

    if config.locomotion.smooth_turn then
        smooth_turn(dt)
    else
        snap_turn(dt)
    end
end

return motion
