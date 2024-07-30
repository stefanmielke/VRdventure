local box_model
local chest_body
local chest_shape

local box_lid_model
local lid_body
local lid_shape

local hinge

local terrain_shader
local terrain_collider

local world

local function on_load()
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
    ]], { flags = { highp = true } })
    lovr.graphics.setBackgroundColor(.05, .05, .05)

    box_model = lovr.graphics.newModel('assets/models/box.glb')
    box_lid_model = lovr.graphics.newModel('assets/models/box_lid.glb')
  
    -- Initialize physics world
    world = lovr.physics.newWorld(0, -9.81, 0)
  
    -- Create terrain collider
    terrain_collider = world:newTerrainCollider(100)
  
    -- Create collider for the chest (static)
    chest_body = world:newCollider(0, 0.25, 0)
    chest_body:setMass(1)
    chest_shape = lovr.physics.newBoxShape(box_model:getDimensions())
    chest_body:addShape(chest_shape)
  
    -- Create collider for the lid (dynamic)
    local width, height, depth = box_model:getDimensions()
    lid_body = world:newCollider(0, height, 0)
    lid_shape = lovr.physics.newBoxShape(box_lid_model:getDimensions())
    lid_body:addShape(lid_shape)
  
    -- Create a hinge joint for the lid
    hinge = lovr.physics.newHingeJoint(chest_body, lid_body, 0, height, 0, 0, 0, 1)
    hinge:setLimits(0, math.pi / 2)  -- Limit the hinge to 90 degrees
  
    -- Variables to track the lid state
    lidOpen = false
end

local function on_update(dt)
    world:update(dt)
    
    if (lovr.headset.wasPressed('left', 'y')) then
        next_scene = require 'scenes.test_scene'
        return
    end
end

function lovr.keypressed(key, scancode, rep)
    if (key == 'b') then
        next_scene = require 'scenes.test_scene'
        return
    end
end

local function on_render(pass)
    -- Draw the chest
    -- pass:draw(box_model, 0, 0.25, 0)
    local x, y, z = chest_body:getPosition()
    pass:draw(box_model, x, y, z, 1, chest_body:getOrientation())
  
    -- Draw the lid
    x, y, z = lid_body:getPosition()
    pass:draw(box_lid_model, x, y, z, 1, lid_body:getOrientation())
  
    -- draw terrain
    pass:setShader(terrain_shader)
    pass:plane(0, 0, 0, 100, 100, -math.pi / 2, 1, 0, 0)
end

local function on_unload()
    world:release()
    box_model:release()
    chest_body:release()
    chest_shape:release()
    
    box_lid_model:release()
    lid_body:release()
    lid_shape:release()
    
    hinge:release()
    
    terrain_shader:release()
    terrain_collider:release()
end

return {
    on_load = on_load,
    on_update = on_update,
    on_render = on_render,
    on_unload = on_unload,
    initial_position = lovr.math.newMat4(),
    name = 'Test Scene'
}