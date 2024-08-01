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

local function move_collider_(grababble, collider, offset, hand)
    local poseRW = mat4(lovr.headset.getPose(hand))
    local handPosition = mat4(motion.pose):mul(poseRW)
    
    if (grababble.grab_type == 'kinetic') then
        local newPose = mat4(handPosition) * offset
        local x, y, z = newPose:getPosition()
        local a, ax, ay, az = newPose:getOrientation()
        collider:setPose(x, y, z, a, ax, ay, az)
    end
end

local function move_collider(hand, drag)
    move_collider_(drag[hand].grababble, drag[hand].collider, drag[hand].offset, hand)
end

return {
    new = new,
    add_new_to_collider = add_new_to_collider,
    get_from_collider = get_from_collider,
    move_collider = move_collider
}