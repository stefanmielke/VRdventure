local helper = require 'helper'

local grabber = {
    collider = nil,
    grababble = nil,
    offset = lovr.math.newMat4(),
    wasKinematic = false
}

local function new()
    return helper.deep_copy(grabber)
end

function grabber.grab(grabber, collider, grababble, offset)
    grabber.collider = collider
    grabber.grababble = grababble
    grabber.offset:set(offset)

    grabber.wasKinematic = collider:isKinematic()
    collider:setKinematic(true)
end

function grabber.release(grabber)
    grabber.collider:setLinearVelocity(0, 0, 0)
    grabber.collider:setAngularVelocity(0, 0, 0)
    if not grabber.wasKinematic then
        grabber.collider:setKinematic(false)
    end

    grabber.collider = nil
    grabber.grababble = nil
end

return {
    new = new
}