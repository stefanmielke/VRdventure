local atmo = require 'atmo.atmo'
local skybox = require('atmo.skybox').new()

local helper = require 'helper'
local model = require 'model'
local grababble = require 'interaction.grababble'
local hands = require 'interaction.hands'

local scene_manager = require 'scenes.scene_manager'

local terrain_shader
local terrain_collider

local colliders = {}
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

    -- setup terrain
    terrain_shader = lovr.graphics.newShader([[
      vec4 lovrmain() {
        return DefaultPosition;
      }
    ]], [[
      const float gridSize = 25.;
      const float cellSize = .5;
  
      vec4 lovrmain() {
        vec2 uv = UV;
  
        // Distance-based alpha (1. at the middle, 0. at edges)
        float alpha = 1. - smoothstep(.15, .50, distance(uv, vec2(.5)));
  
        // Grid coordinate
        uv *= gridSize;
        uv /= cellSize;
        vec2 c = abs(fract(uv - .5) - .5) / fwidth(uv);
        float line = clamp(1. - min(c.x, c.y), 0., 1.);
        vec3 value = mix(vec3(.01, .01, .011), (vec3(.04)), line);
  
        return vec4(vec3(value), alpha);
      }
    ]], {
        flags = {
            highp = true
        }
    })
    lovr.graphics.setBackgroundColor(.05, .05, .05)

    local box_model = lovr.graphics.newModel('assets/models/box.glb')
    local box_lid_model = lovr.graphics.newModel('assets/models/box_lid.glb')
    local apple_model = lovr.graphics.newModel('assets/models/apple.glb')
    local apple_meshes = model.get_meshes_from_model_nodes(apple_model)

    -- Initialize physics world
    world = lovr.physics.newWorld({
        tags = {'grab'}
    })

    hands.set_world(world)

    -- Create terrain collider
    terrain_collider = world:newTerrainCollider(100)

    local apple2_body = world:newSphereCollider(3, 1, 0, 0.1)
    grababble.add_new_to_collider(apple2_body)
    model.add_to_collider(apple2_body, apple_meshes.apple)
    scene_manager.add_tracked_object(apple2_body)

    -- Create collider for the chest
    local box_w, box_h, box_d = box_model:getDimensions()
    local chest_body = world:newConvexCollider(0, 0.25, 0, box_model)
    grababble.add_new_to_collider(chest_body, {
        grab_type = 'physical'
    })
    model.add_to_collider(chest_body, box_model)
    scene_manager.add_tracked_object(chest_body)

    -- Create collider for the lid
    local lid_w, lid_h, lid_d = box_lid_model:getDimensions()
    local lid_body = world:newBoxCollider(0, box_h + (lid_h / 2), 0, lid_w, lid_h, lid_d)
    grababble.add_new_to_collider(lid_body, {
        grab_type = 'physical',
        grab_joint = 'distance'
    })
    model.add_to_collider(lid_body, box_lid_model)
    scene_manager.add_tracked_object(lid_body)

    -- Create a hinge joint for the lid
    local hinge = lovr.physics.newHingeJoint(chest_body, lid_body, box_w / 2, box_h, 0, 0, 0, 1)
    hinge:setLimits((-math.pi / 3) * 2, math.pi / 2) -- Limit the hinge to 90 degrees
    scene_manager.add_tracked_object(hinge)
    
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

    -- draw terrain
    pass:setShader(terrain_shader)
    pass:plane(0, 0, 0, 100, 100, -math.pi / 2, 1, 0, 0)
end

local function on_unload()
    hands.remove_world()

    world:release()

    terrain_shader:release()
    terrain_collider:release()
end

return {
    on_load = on_load,
    on_update = on_update,
    on_pre_render = on_pre_render,
    on_render = on_render,
    on_unload = on_unload,
    initial_position = lovr.math.newMat4(),
    name = 'Test Scene Render From Colliders'
}
