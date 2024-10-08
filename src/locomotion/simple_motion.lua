local config = require 'config'

local simple_motion = {
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

function simple_motion.reset(initial_pose)
    simple_motion.pose:set(initial_pose or lovr.math.Mat4())
end

local function smooth_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        local direction = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
        direction.y = 0

        -- Smooth strafe movement
        if math.abs(x) > config.input.thumbstick_deadzone then
            local strafeVector = quat(-math.pi / 2, 0, 1, 0):mul(vec3(direction))
            simple_motion.pose:translate(strafeVector * x * simple_motion.walking_speed * dt)
        end

        -- Smooth Forward/backward movement
        if math.abs(y) > config.input.thumbstick_deadzone then
            simple_motion.pose:translate(direction * y * simple_motion.walking_speed * dt)
        end
    end
end

local function smooth_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')

        -- Smooth horizontal turning
        if math.abs(x) > config.input.thumbstick_deadzone then
            local headsetPosition = vec3(lovr.headset.getPosition())
            local angle = -x * simple_motion.turning_speed * dt
            local rotationMatrix = mat4():rotate(angle, 0, 1, 0)

            simple_motion.pose:translate(headsetPosition)
            simple_motion.pose:mul(rotationMatrix)
            simple_motion.pose:translate(-headsetPosition)
        end
    end
end

local function snap_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        if math.abs(y) > config.input.thumbstick_deadzone and simple_motion.thumbstick_cooldown_walk < 0 then
            local move_vector = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
            if not simple_motion.flying then
                move_vector.y = 0
            end
            move_vector:mul(y / math.abs(y) * simple_motion.dash_distance)
            simple_motion.pose:translate(move_vector)
            simple_motion.thumbstick_cooldown_walk = simple_motion.thumbstick_cooldown_time_walk
        end
    end

    simple_motion.thumbstick_cooldown_walk = simple_motion.thumbstick_cooldown_walk - dt
end

local function snap_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')
        if math.abs(x) > config.input.thumbstick_deadzone and simple_motion.thumbstick_cooldown_turn < 0 then
            local headsetPosition = vec3(lovr.headset.getPosition())
            local angle = -x / math.abs(x) * simple_motion.snap_turn_angle
            local rotationMatrix = mat4():rotate(angle, 0, 1, 0)

            simple_motion.pose:translate(headsetPosition)
            simple_motion.pose:mul(rotationMatrix)
            simple_motion.pose:translate(-headsetPosition)
            
            simple_motion.thumbstick_cooldown_turn = simple_motion.thumbstick_cooldown_time_turn
        end
    end

    simple_motion.thumbstick_cooldown_turn = simple_motion.thumbstick_cooldown_turn - dt
end

function simple_motion.update(dt)
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

return simple_motion
