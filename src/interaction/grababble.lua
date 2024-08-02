local helper = require 'helper'

local grababble = {
    is_grababble = true, -- if you can grab the object
    grab_type = 'kinetic', -- 'kinetic' (collides with everything), 'physical' (pull the object around when moving, good for joints)
    velocity_mult_on_release = 1, -- velocity to multiply by the hand velocity when released
    grab_joint = 'fixed' -- 'fixed' (allows for rotation), 'distance' (should be used for joints that can be moved around, but have a set rotation)
}

local function new(override_values)
    local new_grababble = helper.deep_copy(grababble)

    if override_values then
        new_grababble.is_grababble = override_values.is_grababble or new_grababble.is_grababble
        new_grababble.grab_type = override_values.grab_type or new_grababble.grab_type
        new_grababble.velocity_mult_on_release = override_values.velocity_mult_on_release or
                                                     new_grababble.velocity_mult_on_release
        new_grababble.grab_joint = override_values.grab_joint or new_grababble.grab_joint
    end

    return new_grababble
end

local function add_to_collider(collider, grababble)
    local current_data = collider:getUserData()
    if not current_data then
        current_data = {}
    end
    current_data.grababble = grababble

    collider:setUserData(current_data)
    collider:setTag('grab')
end

local function add_new_to_collider(collider, override_values)
    add_to_collider(collider, new(override_values))
end

local function get_from_collider(collider)
    local data = collider:getUserData().grababble
    return data.is_grababble and data or nil
end

local function move_collider_(grabber, hand_pose)
    if grabber.grababble.grab_type == 'kinetic' then
        local new_pose = hand_pose * grabber.offset
        local x, y, z = new_pose:getPosition()
        local a, ax, ay, az = new_pose:getOrientation()
        grabber.collider:setPose(x, y, z, a, ax, ay, az)
    elseif grabber.grababble.grab_type == 'physical' then
        -- movement is done on the "hand" module, nothing to be done here yet
    end
end

local function move_collider(hand_pose, grabber)
    move_collider_(grabber, mat4(hand_pose))
end

return {
    new = new,
    add_to_collider = add_to_collider,
    add_new_to_collider = add_new_to_collider,
    get_from_collider = get_from_collider,
    move_collider = move_collider
}
