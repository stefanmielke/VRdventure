local atmo = require 'atmo.atmo'
local skybox = require('atmo.skybox').new()

local model = require 'model'
local hands = require 'interaction.hands'

local motion = require 'locomotion.complex_motion'

local scene_manager = require 'scenes.scene_manager'
local scene_loader = require 'scenes.scene_loader'

local world

local function on_load()
    -- skybox
    atmo.gpu.haze = -0.19 -- controls size of sun's halo
    atmo.gpu.horizon_offset = 0.8 -- moves the horizon line up or down
    atmo.gpu.sun_intensity = 40 -- brightness of sun's disk
    atmo.gpu.sun_sharpness = 0.94 -- controls the halo around the sun
    atmo.gpu.sun_position = Vec3(-0.48, 0.34, -0.64) -- direction, or normalized position of sun in the sky
    atmo.gpu.gamma_correction = 2.2 -- gamma for contrast and brightness adjustment
    atmo.gpu.hue = Vec3(0.04, 0.25, 0.45) -- scattering rgb parameters that affect the overall hue
    skybox:bake(atmo.draw)

    -- Initialize physics world
    world = lovr.physics.newWorld({
        tags = {'body', 'grab', 'hands'}
    })
    world:disableCollisionBetween('body', 'grab')
    world:disableCollisionBetween('body', 'hands')
    world:disableCollisionBetween('body', 'body')
    
    world:setGravity(0, -40, 0)

    scene_loader.load_scene_complete_split_files(world, 'test_scene')

    hands.set_world(world)
    motion.set_world(world)

    -- Create a hinge joint for the lid
    -- local hinge = lovr.physics.newHingeJoint(chest_body, lid_body, box_w / 2, box_h, 0, 0, 0, 1)
    -- hinge:setLimits((-math.pi / 3) * 2, math.pi / 2) -- Limit the hinge to 90 degrees
    -- scene_manager.add_tracked_object(hinge)

end

local function on_update(dt)
    world:update(dt)

    if (lovr.headset.wasPressed('left', 'y')) then
        scene_manager.set_next_scene('test_scene_single_model')
        return
    end

    hands.update_interaction(dt, world)
end

local function on_pre_render(pass)
    skybox:draw(pass)
end

local function on_render(pass)
    model.render_all_model_from_colliders(pass, world)

    -- pass:setColor(1, 0, 0, 1)
    -- pass:setWireframe(true)

    -- local x, y, z = motion.collider:getPosition()
    -- local angle, ax, ay, az = motion.collider:getOrientation()
    -- pass:capsule(x, y, z, motion.collider:getShapes()[1]:getRadius(), motion.collider:getShapes()[1]:getLength(), angle,
    --     ax, ay, az)

    -- local x, y, z = motion.head_collision:getPosition()
    -- local angle, ax, ay, az = motion.head_collision:getOrientation()
    -- pass:sphere(x, y, z, motion.head_collision:getShapes()[1]:getRadius(), angle, ax, ay, az, 6)

    -- local joint = motion.head_collision:getJoints()[1]
    -- local x1, y1, z1, x2, y2, z2 = joint:getAnchors()

    -- pass:setColor(1, 0, 0, 1)
    -- pass:sphere(x1, y1, z1, .01)

    -- pass:setColor(0, 1, 0, 1)
    -- pass:sphere(x2, y2, z2, .01)

    -- pass:setColor(0, 0, 1, 1)
    -- pass:line(x1, y1, z1, x2, y2, z2)

    -- pass:setWireframe(false)
    -- pass:setColor(1, 1, 1, 1)
end

local function on_unload()
    hands.remove_world()

    world:release()
end

local function get_initial_position()
    if scene_manager.get_reference_object('Spawn') then
        return scene_manager.get_reference_object('Spawn').pose
    else
        return lovr.math.newMat4()
    end
end

return {
    on_load = on_load,
    on_update = on_update,
    on_pre_render = on_pre_render,
    on_render = on_render,
    on_unload = on_unload,
    initial_position = function()
        return get_initial_position()
    end,
    name = 'Test Scene Render From Single Model'
}
