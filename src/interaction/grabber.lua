local helper = require 'helper'

local grabber = {
    collider = nil,
    grababble = nil,
    offset = lovr.math.newMat4(),
    was_kinematic = false,

    hand_temp_collider = nil,
    hand_temp_joint = nil
}

local function new()
    return helper.deep_copy(grabber)
end

function grabber.grab(grabber, collider, grababble, hand_pose, world)
    local offset = hand_pose:invert():mul(mat4(collider:getPose()))

    grabber.collider = collider
    grabber.grababble = grababble
    grabber.offset:set(offset)

    if grabber.grababble.grab_type == 'kinetic' then
        grabber.was_kinematic = collider:isKinematic()
        collider:setKinematic(true)
    elseif grabber.grababble.grab_type == 'physical' then
        grabber.was_kinematic = collider:isKinematic()

        grabber.hand_temp_collider = world:newSphereCollider(vec3(hand_pose:getPosition()), .01)
        grabber.hand_temp_collider:setKinematic(true)
        grabber.hand_temp_collider:setSensor(true)

        grabber.hand_temp_joint = lovr.physics.newWeldJoint(grabber.hand_temp_collider, collider)
        -- grabber.hand_temp_joint = lovr.physics.newDistanceJoint(grabber.hand_temp_collider, collider,
        --     vec3(hand_pose:getPosition()), vec3(hand_pose:getPosition()))
        -- grabber.hand_temp_joint:setLimits(0, 0)
    end
end

function grabber.release(grabber, velocity)
    if grabber.grababble.grab_type == 'kinetic' then
        grabber.collider:setLinearVelocity(velocity:mul(grabber.grababble.velocity_mult_on_release))
        grabber.collider:setAngularVelocity(0, 0, 0)
    elseif grabber.grababble.grab_type == 'physical' then
        grabber.collider:setLinearVelocity(velocity:mul(grabber.grababble.velocity_mult_on_release))
        grabber.collider:setAngularVelocity(0, 0, 0)
        grabber.hand_temp_joint:destroy()
        grabber.hand_temp_joint:release()
        grabber.hand_temp_joint = nil
        grabber.hand_temp_collider:destroy()
        grabber.hand_temp_collider:release()
        grabber.hand_temp_collider = nil
    end

    if not grabber.was_kinematic then
        grabber.collider:setKinematic(false)
    end

    grabber.collider = nil
    grabber.grababble = nil
end

return {
    new = new
}
