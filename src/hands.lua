local hand_data

local function get_controller_data()
    return {
        grab_point = lovr.math.newMat4(),
        models = {
            left = 'assets/models/hand/left.glb',
            right = 'assets/models/hand/right.glb'
        }
    }
end

local function load()
    local controller_data = get_controller_data()

    hand_data = {
        grab_point = controller_data.grab_point,
        models = {
            left = lovr.graphics.newModel(controller_data.models.left),
            right = lovr.graphics.newModel(controller_data.models.right)
        }
    }
end

local function render(pass, player_position)
    for hand, model in pairs(hand_data.models) do
        if lovr.headset.isTracked(hand) then
            lovr.headset.animate(model)
            -- Whenever pose of hand or head is used, need to account for VR movement
            local poseRW = mat4(lovr.headset.getPose(hand))
            local poseVR = mat4(player_position):mul(poseRW)

            pass:setColor(0.1, 0.1, 1, 0.1)
            pass:setWireframe(true)
            pass:draw(model, poseVR)
            pass:setWireframe(false)
            pass:setColor(1, 1, 1, 1)

            local x, y, z = poseVR:getPosition()
            pass:sphere(x, y, z, .01)            
        end
    end
end

return {
    load = load,
    render = render,
}