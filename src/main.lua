
local hand_models
local box_model
local box_lid_model

local terrain_shader

function lovr.load()
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

  hand_models = {
    left = lovr.graphics.newModel('assets/models/hand/left.glb'),
    right = lovr.graphics.newModel('assets/models/hand/right.glb')
  }

  box_model = lovr.graphics.newModel('assets/models/box.glb')
  box_lid_model = lovr.graphics.newModel('assets/models/box_lid.glb')

  -- Initialize physics world
  -- world = lovr.physics.newWorld(0, 0, 0)

  -- -- Create terrain
  -- collider = world:newTerrainCollider(100)

  -- -- Create collider for the chest (static)
  -- chestBody = world:newCollider(0, 0.25, 0)
  -- chestShape = lovr.physics.newBoxShape(box_model:getDimensions())
  -- chestBody:addShape(chestShape)

  -- Create collider for the lid (dynamic)
  -- width, height, depth = box_model:getDimensions()
  -- lidBody = world:newCollider(0, height / 2, 0)
  -- lidShape = lovr.physics.newBoxShape(box_lid_model:getDimensions())
  -- lidBody:addShape(lidShape)

  -- -- Create a hinge joint for the lid
  -- hinge = lovr.physics.newHingeJoint(chestBody, lidBody, 0, height / 2, 0, 0, 0, 1)
  -- hinge:setLimits(0, math.pi / 2)  -- Limit the hinge to 90 degrees

  -- Variables to track the lid state
  lidOpen = false
end

function lovr.update(dt)
  if (lovr.headset.wasPressed('left', 'menu')) then
    lovr.event.quit()
    return
  end

  -- world:update(dt)
end

function lovr.draw(pass)
  for hand, model in pairs(hand_models) do
    if lovr.headset.isTracked(hand) then
      lovr.headset.animate(model)
      pass:draw(model, mat4(lovr.headset.getPose(hand)))
    end
  end
  
  -- Draw the chest
  pass:draw(box_model, 0, 0.25, 0)
  -- pass:draw(box_model, chestBody:getPosition(), chestBody:getOrientation())

  -- Draw the lid
  -- pass:draw(box_lid_model, lidBody:getPosition(), lidBody:getOrientation())

  -- draw terrain
  pass:setShader(terrain_shader)
  pass:plane(0, 0, 0, 100, 100, -math.pi / 2, 1, 0, 0)
end
