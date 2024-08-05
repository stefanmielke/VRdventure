local config = require 'config'

local complex_motion = {
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
    walking_speed = 4,

    world = nil
}

function complex_motion.set_world(world)
    complex_motion.world = world
end

function complex_motion.reset(initial_pose)
    complex_motion.pose:set(initial_pose or lovr.math.Mat4())
end

local function smooth_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        local direction = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
        direction.y = 0

        -- Smooth strafe movement
        if math.abs(x) > config.input.thumbstick_deadzone then
            local strafeVector = quat(-math.pi / 2, 0, 1, 0):mul(vec3(direction))
            complex_motion.pose:translate(strafeVector * x * complex_motion.walking_speed * dt)
        end

        -- Smooth Forward/backward movement
        if math.abs(y) > config.input.thumbstick_deadzone then
            complex_motion.pose:translate(direction * y * complex_motion.walking_speed * dt)
        end
    end
end

local function smooth_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')

        -- Smooth horizontal turning
        if math.abs(x) > config.input.thumbstick_deadzone then
            local headset_position = vec3(lovr.headset.getPosition())
            local angle = -x * complex_motion.turning_speed * dt
            local rotation_matrix = mat4():rotate(angle, 0, 1, 0)

            complex_motion.pose:translate(headset_position)
            complex_motion.pose:mul(rotation_matrix)
            complex_motion.pose:translate(-headset_position)
        end
    end
end

local function snap_walk(dt)
    if lovr.headset.isTracked(config.locomotion.walk_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.walk_stick, 'thumbstick')
        if math.abs(y) > config.input.thumbstick_deadzone and complex_motion.thumbstick_cooldown_walk < 0 then
            local move_vector = quat(lovr.headset.getOrientation(config.locomotion.motion_direction)):direction()
            if not complex_motion.flying then
                move_vector.y = 0
            end
            move_vector:mul(y / math.abs(y) * complex_motion.dash_distance)
            complex_motion.pose:translate(move_vector)
            complex_motion.thumbstick_cooldown_walk = complex_motion.thumbstick_cooldown_time_walk
        end
    end

    complex_motion.thumbstick_cooldown_walk = complex_motion.thumbstick_cooldown_walk - dt
end

local function snap_turn(dt)
    if lovr.headset.isTracked(config.locomotion.turn_stick) then
        local x, y = lovr.headset.getAxis(config.locomotion.turn_stick, 'thumbstick')
        if math.abs(x) > config.input.thumbstick_deadzone and complex_motion.thumbstick_cooldown_turn < 0 then
            local headset_position = vec3(lovr.headset.getPosition())
            local angle = -x / math.abs(x) * complex_motion.snap_turn_angle
            local rotation_matrix = mat4():rotate(angle, 0, 1, 0)

            complex_motion.pose:translate(headset_position)
            complex_motion.pose:mul(rotation_matrix)
            complex_motion.pose:translate(-headset_position)

            complex_motion.thumbstick_cooldown_turn = complex_motion.thumbstick_cooldown_time_turn
        end
    end

    complex_motion.thumbstick_cooldown_turn = complex_motion.thumbstick_cooldown_turn - dt
end

local function update_height(dt, world)
    -- Cast a ray through the sphere
    local headset_position = vec3(lovr.headset.getPosition())
    local headset_global_pose = mat4(complex_motion.pose):translate(headset_position)

    local _, motion_y, _ = complex_motion.pose:getPosition()

    local x1, y1, z1 = headset_global_pose:getPosition()
    local y2 = y1 - (y1 - motion_y)

    -- check collision inside the body
    world:raycast(x1, y1, z1, x1, y2, z1, nil, function(collider, shape, x, y, z, nx, ny, nz, fraction)
        complex_motion.pose:translate(0, 3 * dt, 0)
        return 0
    end)
    
    local collision = false
    world:raycast(x1, y1, z1, x1, y2 - 0.1, z1, nil, function(collider, shape, x, y, z, nx, ny, nz, fraction)
        collision = true
        return 0
    end)

    if not collision then
        local gx, gy, gz = world:getGravity()
        complex_motion.pose:translate(0, -4 * dt, 0)
    end
end

function complex_motion.update(dt, world)
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

    if complex_motion.world then
        update_height(dt, complex_motion.world)
    end
end

return complex_motion
