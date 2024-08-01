local motion = {
    pose = lovr.math.newMat4(), -- Transformation in VR initialized to origin (0,0,0) looking down -Z
    thumbstick_deadzone = 0.4, -- Smaller thumbstick displacements are ignored (too much noise)
    direction_from = 'head', -- Movement can be relative to orientation of head or left/right controller

    -- Snap motion parameters
    snap_turn_angle = 2 * math.pi / 12,
    dash_distance = 1.5,
    thumbstick_cooldown_time = 0.3,
    thumbstick_cooldown = 0,

    -- Smooth motion parameters
    turning_speed = 2 * math.pi * 1 / 6,
    walking_speed = 4
}

function motion.reset(initial_pose)
    motion.pose:set(initial_pose or lovr.math.Mat4())
end

function motion.smooth(dt)
    if lovr.headset.isTracked('right') then
        local x, y = lovr.headset.getAxis('right', 'thumbstick')

        -- Smooth horizontal turning
        if math.abs(x) > motion.thumbstick_deadzone then
            motion.pose:rotate(-x * motion.turning_speed * dt, 0, 1, 0)
        end
    end
    if lovr.headset.isTracked('left') then
        local x, y = lovr.headset.getAxis('left', 'thumbstick')
        local direction = quat(lovr.headset.getOrientation(motion.direction_from)):direction()

        -- Smooth strafe movement
        if math.abs(x) > motion.thumbstick_deadzone then
            local strafeVector = quat(-math.pi / 2, 0, 1, 0):mul(vec3(direction))
            motion.pose:translate(strafeVector * x * motion.walking_speed * dt)
        end

        -- Smooth Forward/backward movement
        if math.abs(y) > motion.thumbstick_deadzone then
            motion.pose:translate(direction * y * motion.walking_speed * dt)
        end
    end
end

function motion.snap(dt)
    -- Snap horizontal turning
    if lovr.headset.isTracked('right') then
        local x, y = lovr.headset.getAxis('right', 'thumbstick')
        if math.abs(x) > motion.thumbstick_deadzone and motion.thumbstick_cooldown < 0 then
            local angle = -x / math.abs(x) * motion.snap_turn_angle
            motion.pose:rotate(angle, 0, 1, 0)
            motion.thumbstick_cooldown = motion.thumbstick_cooldown_time
        end
    end

    -- Dashing forward/backward
    if lovr.headset.isTracked('left') then
        local x, y = lovr.headset.getAxis('left', 'thumbstick')
        if math.abs(y) > motion.thumbstick_deadzone and motion.thumbstick_cooldown < 0 then
            local moveVector = quat(lovr.headset.getOrientation('head')):direction()
            if not motion.flying then
                moveVector.y = 0
            end
            moveVector:mul(y / math.abs(y) * motion.dash_distance)
            motion.pose:translate(moveVector)
            motion.thumbstick_cooldown = motion.thumbstick_cooldown_time
        end
    end

    motion.thumbstick_cooldown = motion.thumbstick_cooldown - dt
end

function motion.update(dt)
    motion.direction_from = lovr.headset.isDown('left', 'trigger') and 'left' or 'head'
    if lovr.headset.isDown('right', 'grip') then
        motion.snap(dt)
    else
        motion.smooth(dt)
    end
end

return motion
