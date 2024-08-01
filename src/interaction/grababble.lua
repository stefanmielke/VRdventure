local helper = require 'helper'
local hands = require 'interaction.hands'

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
    local handPosition = mat4(hands.data[hand].global_pose)
    
    if (grababble.grab_type == 'kinetic') then
        local newPose = handPosition * offset
        local x, y, z = newPose:getPosition()
        local a, ax, ay, az = newPose:getOrientation()
        collider:setPose(x, y, z, a, ax, ay, az)
    end
end

local function move_collider(hand, grabber)
    move_collider_(grabber.grababble, grabber.collider, grabber.offset, hand)
end

return {
    new = new,
    add_new_to_collider = add_new_to_collider,
    get_from_collider = get_from_collider,
    move_collider = move_collider
}