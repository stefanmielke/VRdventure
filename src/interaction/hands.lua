local motion = require 'locomotion.motion'

local grabber = require 'interaction.grabber'
local grababble = require 'interaction.grababble'

local data = {}

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

    data['hand/left'] = {
        grabber = grabber.new(),
        model = lovr.graphics.newModel(controller_data.models.left),
        global_pose = lovr.math.newMat4()
    }
    data['hand/right'] = {
        grabber = grabber.new(),
        model = lovr.graphics.newModel(controller_data.models.right),
        global_pose = lovr.math.newMat4()
    }
end

local function update_model()
    for hand, _ in pairs(data) do
        local poseRW = mat4(lovr.headset.getPose(hand))
        data[hand].global_pose = mat4(motion.pose):mul(poseRW)
    end
end
    
local function update_interaction(dt, world)
    for _, hand in ipairs(lovr.headset.getHands()) do
        if not data[hand].grabber.collider and lovr.headset.isDown(hand, 'trigger') then
            local x, y, z = data[hand].global_pose:getPosition()
            local collider = world:querySphere(x, y, z, .01)
            if (collider) then
                local grababble = grababble.get_from_collider(collider)
                if grababble then
                    local hand_pose = mat4(data[hand].global_pose)

                    local offset = hand_pose:invert():mul(mat4(collider:getPose()))
                    data[hand].grabber:grab(collider, grababble, offset)
                end
            end
        end

        if data[hand].grabber.collider then
            grababble.move_collider(data[hand].global_pose, data[hand].grabber)

            if not lovr.headset.isDown(hand, 'trigger') then
                data[hand].grabber:release()
            end
        end
    end
end

local function render(pass)
    for hand, values in pairs(data) do
        if lovr.headset.isTracked(hand) then
            lovr.headset.animate(values.model)

            pass:setColor(0.1, 0.1, 1, 0.1)
            pass:setWireframe(true)
            pass:draw(values.model, data[hand].global_pose)
            pass:setWireframe(false)


            pass:setColor(1, 1, 1, 1)

            local x, y, z = data[hand].global_pose:getPosition()
            pass:sphere(x, y, z, .01)

            pass:setColor(1, 1, 1, 1)
        end
    end
end

return {
    data = data,
    load = load,
    update_model = update_model,
    update_interaction = update_interaction,
    render = render
}
