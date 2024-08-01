local grabber = require 'grabber'

local function get_controller_data()
    return {
        models = {
            left = 'assets/models/hand/left.glb',
            right = 'assets/models/hand/right.glb'
        }
    }
end

local function load()
    local controller_data = get_controller_data()

    hands = {
        ['hand/left'] = {
            grabber = grabber.new(),
            model = lovr.graphics.newModel(controller_data.models.left),
            global_pose = lovr.math.newMat4()
        },
        ['hand/right'] = {
            grabber = grabber.new(),
            model = lovr.graphics.newModel(controller_data.models.right),
            global_pose = lovr.math.newMat4()
        },
    }
end

local function update()
    for hand, _ in pairs(hands) do
        local poseRW = mat4(lovr.headset.getPose(hand))
        hands[hand].global_pose = mat4(motion.pose):mul(poseRW)
    end
end

local function render(pass)
    for hand, values in pairs(hands) do
        if lovr.headset.isTracked(hand) then
            lovr.headset.animate(values.model)

            pass:setColor(0.1, 0.1, 1, 0.1)
            pass:setWireframe(true)
            pass:draw(values.model, hands[hand].global_pose)
            pass:setWireframe(false)
            pass:setColor(1, 1, 1, 1)

            local x, y, z = hands[hand].global_pose:getPosition()
            pass:sphere(x, y, z, .01)            
        end
    end
end

return {
    load = load,
    update = update,
    render = render,
}