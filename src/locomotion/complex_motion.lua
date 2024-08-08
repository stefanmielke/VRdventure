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

    world = nil,
    collider = nil,
    collision_shape = nil,
    collision_shape_radius = 0.2,

    head_collision = nil,
    current_height = 1
}

function complex_motion.set_world(world)
    complex_motion.world = world

    complex_motion.collider = nil
    complex_motion.collision_shape = nil

    local headset_position = vec3(lovr.headset.getPosition('head'))
    local headset_global_pose = mat4(complex_motion.pose):translate(headset_position)
    local _, motion_y, _ = complex_motion.pose:getPosition()
    local x1, y1, z1 = headset_global_pose:getPosition()

    complex_motion.current_height = y1 - motion_y

    complex_motion.head_collision = world:newSphereCollider(x1, y1, z1, 0.1)
    complex_motion.head_collision:setKinematic(true)
    complex_motion.head_collision:setSleepingAllowed(false)
    complex_motion.head_collision:setSensor(true)
    complex_motion.head_collision:setTag('body')

    local x, y, z = complex_motion.pose:getPosition()
    complex_motion.collider = world:newCollider(x, y + complex_motion.current_height / 2, z)
    complex_motion.collision_shape = lovr.physics.newCapsuleShape(complex_motion.collision_shape_radius, complex_motion.current_height)
    complex_motion.collider:addShape(complex_motion.collision_shape)
    complex_motion.collider:setSleepingAllowed(false)
    complex_motion.collider:setOrientation(math.pi / 2, 1, 0, 0)
    complex_motion.collider:setDegreesOfFreedom('xyz', nil)
    complex_motion.collider:setLinearDamping(1)
    complex_motion.collider:setTag('body')
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
    -- update height
    local headset_position = vec3(lovr.headset.getPosition('head'))
    local headset_global_pose = mat4(complex_motion.pose):translate(headset_position)

    local _, motion_y, _ = complex_motion.pose:getPosition()

    local x1, y1, z1 = headset_global_pose:getPosition()

    local next_length = y1 - motion_y
    local last_length = complex_motion.collision_shape:getLength()

    -- update position of the collider to match the position of the player
    local x, y, z = complex_motion.collider:getPosition()
    complex_motion.collision_shape:setLength(next_length)
    complex_motion.collider:setPosition(x, y + next_length - last_length, z)
    
    complex_motion.current_height = y1 - motion_y

    local hx, hy, hz = ((vec3(headset_global_pose:getPosition()) - vec3(complex_motion.collider:getPosition())) / dt):unpack()

    local _, ly, _ = complex_motion.collider:getLinearVelocity()
    complex_motion.collider:setLinearVelocity(hx, ly, hz)
end

function complex_motion.update(dt, world)
    if config.locomotion.smooth_walk then
        smooth_walk(dt)
    else
        snap_walk(dt)
    end

    if complex_motion.head_collision then
        local headset_position = vec3(lovr.headset.getPosition())
        local headset_global_pose = mat4(complex_motion.pose):translate(headset_position)

        local x, y, z = headset_global_pose:getPosition()
        complex_motion.head_collision:setPosition(x, y, z)
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

function complex_motion.post_update(dt, world)
    local headset_position = vec3(lovr.headset.getPosition())
    local headset_global_pose = mat4(complex_motion.pose):translate(headset_position)

    local hx, hy, hz = headset_global_pose:getPosition()
    local cx, cy, cz = complex_motion.collider:getPosition()
    local final_distance = (vec3(hx, 0, hz) - vec3(cx, 0, cz)):distance()
    if final_distance > 0.2 then
        print('invalid position')
    end

    local x, _, z = complex_motion.pose:getPosition()
    local _, ny, _ = complex_motion.collider:getPosition()
    complex_motion.pose:set(vec3(x, ny - (complex_motion.current_height / 2) - .15, z), quat(complex_motion.pose:getOrientation()))
    print(complex_motion.collision_shape:getInertia())
end

return complex_motion
