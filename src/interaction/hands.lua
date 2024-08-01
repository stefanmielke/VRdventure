local config = require 'config'

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
        global_pose = lovr.math.newMat4(),
        previous_global_pose = lovr.math.newMat4(),
        collider_color = {1, 1, 1, 1},
        velocity = lovr.math.newVec3()
    }
    data['hand/right'] = {
        grabber = grabber.new(),
        model = lovr.graphics.newModel(controller_data.models.right),
        global_pose = lovr.math.newMat4(),
        previous_global_pose = lovr.math.newMat4(),
        collider_color = {1, 1, 1, 1},
        velocity = lovr.math.newVec3()
    }
end

local function set_world(world)
    for _, values in pairs(data) do
        values.grabber.hand_collider = world:newSphereCollider(vec3(values.global_pose:getPosition()), .01)
        values.grabber.hand_collider:setKinematic(true)
        values.grabber.hand_collider:setSensor(true)
    end
end

local function remove_world()
    for _, values in pairs(data) do
        if values.grabber.hand_collider then
            values.grabber.hand_collider:destroy()
            values.grabber.hand_collider:release()
            values.grabber.hand_collider = nil
        end
    end
end

local function update_model()
    for hand, values in pairs(data) do
        local pose_rw = mat4(lovr.headset.getPose(hand))

        values.previous_global_pose:set(values.global_pose)
        values.global_pose:set(motion.pose):mul(pose_rw)
    end
end

local function update_interaction(dt, world)
    for _, hand in ipairs(lovr.headset.getHands()) do
        data[hand].velocity:set(data[hand].global_pose:getPosition())
        data[hand].velocity:sub(data[hand].previous_global_pose:getPosition())
        data[hand].velocity:mul(1 / dt)

        if not data[hand].grabber.collider then
            local x, y, z = data[hand].global_pose:getPosition()
            local collider = world:querySphere(x, y, z, .01)
            if (collider) then
                data[hand].collider_color = {1, 1, 1, 1}
                if lovr.headset.isDown(hand, 'trigger') then
                    local grababble = grababble.get_from_collider(collider)
                    if grababble then
                        data[hand].grabber:grab(collider, grababble, mat4(data[hand].global_pose), world)
                    end
                end
            else
                data[hand].collider_color = {1, 1, 1, .1}
            end
        end

        if data[hand].grabber.collider then
            grababble.move_collider(data[hand].global_pose, data[hand].grabber)

            if not lovr.headset.isDown(hand, 'trigger') then
                data[hand].grabber:release(vec3(data[hand].velocity))
            end
        end
    end
end

local function render(pass)
    for hand, values in pairs(data) do
        if lovr.headset.isTracked(hand) then
            lovr.headset.animate(values.model)

            pass:setColor(1, 1, 1, 0.01)
            pass:setWireframe(true)
            pass:draw(values.model, values.global_pose)
            pass:setWireframe(false)

            pass:setColor(values.collider_color)
            local x, y, z = values.global_pose:getPosition()
            pass:sphere(x, y, z, .01)

            if config.debug.show then
                if values.grabber.hand_temp_joint then
                    local x1, y1, z1, x2, y2, z2 = values.grabber.hand_temp_joint:getAnchors()

                    pass:setColor(1, 0, 0, 1)
                    pass:sphere(x1, y1, z1, .01)

                    pass:setColor(0, 1, 0, 1)
                    pass:sphere(x2, y2, z2, .01)

                    pass:setColor(0, 0, 1, 1)
                    pass:line(x1, y1, z1, x2, y2, z2)
                end
            end

            pass:setColor(1, 1, 1, 1)
        end
    end
end

return {
    data = data,
    load = load,
    set_world = set_world,
    remove_world = remove_world,
    update_model = update_model,
    update_interaction = update_interaction,
    render = render
}
