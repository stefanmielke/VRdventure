local atmo = require 'atmo.atmo'
local skybox = require('atmo.skybox').new()

local model = require 'model'
local hands = require 'interaction.hands'

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
        tags = {'grab'}
    })

    hands.set_world(world)

    scene_loader.load_scene_complete_single_file(world, 'test_scene_playground')

    -- Create a hinge joint for the lid
    -- local hinge = lovr.physics.newHingeJoint(chest_body, lid_body, box_w / 2, box_h, 0, 0, 0, 1)
    -- hinge:setLimits((-math.pi / 3) * 2, math.pi / 2) -- Limit the hinge to 90 degrees
    -- scene_manager.add_tracked_object(hinge)
    
end

local function on_update(dt)
    world:update(dt)

    if (lovr.headset.wasPressed('left', 'y')) then
        scene_manager.set_next_scene('test_scene_playground')
        return
    end

    hands.update_interaction(dt, world)
end

local function on_pre_render(pass)
    skybox:draw(pass)
end

local function on_render(pass)
    model.render_all_model_from_colliders(pass, world)
end

local function on_unload()
    hands.remove_world()

    world:release()
end

local function get_initial_position()
    return scene_manager.get_reference_object('Spawn').pose
end

return {
    on_load = on_load,
    on_update = on_update,
    on_pre_render = on_pre_render,
    on_render = on_render,
    on_unload = on_unload,
    initial_position = function() return get_initial_position() end,
    name = 'Test Scene Render From Single Model'
}
