local helper = require 'helper'

-- grab_type = 'kinetic', 'physical'
local grababble = {
    is_grababble = true,
    grab_type = 'kinetic'
}

local function new()
    return helper.deep_copy(grababble)
end

local function add_new_to_collider(collider)
    collider:setUserData(new())
end

local function get_from_collider(collider)
    local data = collider:getUserData()
    return data.is_grababble and data or nil
end

local function move_collider_(grababble, collider, offset, hand_pose)

    if (grababble.grab_type == 'kinetic') then
        local new_pose = hand_pose * offset
        local x, y, z = new_pose:getPosition()
        local a, ax, ay, az = new_pose:getOrientation()
        collider:setPose(x, y, z, a, ax, ay, az)
    end
end

local function move_collider(hand_pose, grabber)
    move_collider_(grabber.grababble, grabber.collider, grabber.offset, mat4(hand_pose))
end

return {
    new = new,
    add_new_to_collider = add_new_to_collider,
    get_from_collider = get_from_collider,
    move_collider = move_collider
}
