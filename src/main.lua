
local hand_models
local box_model
local box_lid_model
local terrain_shader


local z = 0
local light_pos = lovr.math.newVec3(0, 4.0, z)
local light_orthographic = false -- Use orthographic light
local shadow_map_size = 2048

local debug_render_from_light = false -- Enable to render scene from light
local debug_show_shadow_map = false -- Enable to view shadow map in overlap

local shader, render_texture
local shadow_map_texture, shadow_map_sampler
local light_space_matrix
local shadow_map_pass, lighting_pass

local function lighting_shader()
  local vs = [[
    vec4 lovrmain() {
      return Projection * View * Transform * VertexPosition;
    }
  ]]

  local fs = [[
    Constants {
      vec3 lightPos;
      mat4 lightSpaceMatrix;
      bool lightOrthographic;
    };

    layout(set = 2, binding = 0) uniform texture2D shadowMapTexture;

    vec4 diffuseLighting(vec3 lightDir, vec3 normal, float shadow) {
      float diff = max(dot(normal, lightDir), 0.0);
      vec4 diffuse = diff * vec4(1.0, 1.0, 0.8, 1.0);
      vec4 baseColor = Color * getPixel(ColorTexture, UV);
      vec4 ambience = vec4(0.05, 0.05, 0.1, 1.0);
      return baseColor * (ambience + (1 - shadow) * diffuse);
    }

    // Falloff shadow near edge of light bounds/frustum
    float shadowFalloff(vec2 uv) {
      const float margin = 0.05;
      uv = clamp(uv, vec2(0,0), vec2(1,1));
      float dx = 1;
      if (uv.x < margin) dx = uv.x / margin;
      else if (uv.x > 1 - margin) dx = ( 1 - uv.x ) / margin;
      float dy = 1;
      if (uv.y < margin) dy = uv.y / margin;
      else if (uv.y > 1 - margin) dy = ( 1 - uv.y ) / margin;
      return dx * dy;
    }

    vec4 lovrmain() {
      vec3 lightDir = normalize(lightPos - PositionWorld);
      vec3 normal = normalize(Normal);
      vec4 positionLightSpace = lightSpaceMatrix * vec4(PositionWorld, 1);
      vec3 positionLightSpaceProj = 0.5 * (positionLightSpace.xyz / positionLightSpace.w) + 0.5;
      vec4 shadowMap = getPixel(shadowMapTexture, positionLightSpaceProj.xy);
      float closestDepth = shadowMap.r * 0.5 + 0.5;
      float currentDepth = positionLightSpaceProj.z;
      float bias = max(0.05 * (1.0 - dot(normal, lightDir)), 0.005);
      float falloff = shadowFalloff(positionLightSpaceProj.xy);
      float shadow;
      if (lightOrthographic) {
        shadow = ((currentDepth - bias) >= closestDepth) ? 1.0 : 0.0;
      } else {
        shadow = ((currentDepth + bias) <= closestDepth) ? 1.0 : 0.0;
      }
      return diffuseLighting(lightDir, normal, falloff * shadow);
    }
  ]]

  return lovr.graphics.newShader(vs, fs, {})
end

local function render_shadow_map(draw)
  local near_plane = 2
  local projection
  if light_orthographic then
    local radius = 3
    local far_plane = 15
    projection = mat4():orthographic(-radius, radius, -radius, radius, near_plane, far_plane)
  else
    projection = mat4():perspective(math.pi / 3, 1, near_plane)
  end

  local view = mat4():lookAt(light_pos, vec3(0, 1, z))

  light_space_matrix = mat4(projection):mul(view)

  shadow_map_pass:reset()
  shadow_map_pass:setProjection(1, projection)
  shadow_map_pass:setViewPose(1, view, true)
  if light_orthographic then
    -- Note for ortho projection with a far plane the depth coord is reversed
    shadow_map_pass:setDepthTest('lequal')
  end

  if debug_render_from_light then
    shadow_map_pass:setShader(shader)
    shadow_map_pass:send('lightPos', light_pos)
  end

  draw(shadow_map_pass)
end

local function render_lighting_pass(draw)
  lighting_pass:reset()

  if lovr.headset then
    for i = 1, lovr.headset.getViewCount() do
      lighting_pass:setViewPose(i, lovr.headset.getViewPose(i))
      lighting_pass:setProjection(i, lovr.headset.getViewAngles(i))
    end
  else
    local t = lovr.timer.getTime()
    lighting_pass:setViewPose(1, 0, 3 - math.sin(t * 0.1), 4, -math.pi / 8, 1, 0, 0)
  end

  lighting_pass:setShader(shader)
  lighting_pass:setSampler(shadow_map_sampler)
  lighting_pass:send('shadowMapTexture', shadow_map_texture)
  lighting_pass:send('lightPos', light_pos)
  lighting_pass:send('lightSpaceMatrix', light_space_matrix)
  lighting_pass:send('lightOrthographic', light_orthographic)
  draw(lighting_pass)
  lighting_pass:setShader()

  lighting_pass:setColor(1, 1, 1, 1)
  lighting_pass:sphere(light_pos, 0.1)
end

local function debug_passes(pass)
  pass:setDepthWrite(false)

  if debug_render_from_light then
    pass:fill(shadow_map_texture)
  else
    pass:fill(render_texture)
    if debug_show_shadow_map then
      -- Render shadow map in overlay
      local width, height = lovr.system.getWindowDimensions()
      pass:setViewport(0, 0, width / 4, height / 4)
      pass:fill(shadow_map_texture)
    end
  end
end


function lovr.load()
  shader = lighting_shader()
  lovr.graphics.setBackgroundColor(0x4782B3)

  local shadow_map_format = debug_render_from_light and 'rgba8' or 'd32f'

  shadow_map_texture = lovr.graphics.newTexture(shadow_map_size, shadow_map_size, {
    format = shadow_map_format,
    linear = false,
    mipmaps = false
  })

  shadow_map_sampler = lovr.graphics.newSampler({ wrap = 'clamp' })

  if lovr.headset then
    local width, height = lovr.headset.getDisplayDimensions()
    local layers = lovr.headset.getViewCount()
    render_texture = lovr.graphics.newTexture(width, height, layers, { mipmaps = false })
  else
    local width, height = lovr.system.getWindowDimensions()
    render_texture = lovr.graphics.newTexture(width, height, 1, { mipmaps = false })
  end

  if debug_render_from_light then
    shadow_map_pass = lovr.graphics.newPass({ shadow_map_texture, samples = 1 })
  else
    shadow_map_pass = lovr.graphics.newPass({ depth = shadow_map_texture, samples = 1 })
    shadow_map_pass:setClear({ depth = light_orthographic and 1 or 0 })
  end

  lighting_pass = lovr.graphics.newPass(render_texture)
  
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
  world = lovr.physics.newWorld(0, -9.81, 0)

  -- Create terrain
  collider = world:newTerrainCollider(100)

  -- Create collider for the chest (static)
  chestBody = world:newCollider(0, 0.25, 0)
  chestBody:setMass(1)
  chestShape = lovr.physics.newBoxShape(box_model:getDimensions())
  chestBody:addShape(chestShape)

  -- Create collider for the lid (dynamic)
  width, height, depth = box_model:getDimensions()
  lidBody = world:newCollider(0, height, 0)
  lidShape = lovr.physics.newBoxShape(box_lid_model:getDimensions())
  lidBody:addShape(lidShape)

  -- Create a hinge joint for the lid
  hinge = lovr.physics.newHingeJoint(chestBody, lidBody, 0, height, 0, 0, 0, 1)
  hinge:setLimits(0, math.pi / 2)  -- Limit the hinge to 90 degrees

  -- Variables to track the lid state
  lidOpen = false
end

function lovr.update(dt)
  if (lovr.headset.wasPressed('left', 'menu')) then
    lovr.event.quit()
    return
  end

  world:update(dt)
end

local function render_scene(pass)
  pass:push()
  for hand, model in pairs(hand_models) do
    if lovr.headset.isTracked(hand) then
      lovr.headset.animate(model)
      pass:draw(model, mat4(lovr.headset.getPose(hand)))
    end
  end
  
  -- Draw the chest
  -- pass:draw(box_model, 0, 0.25, 0)
  local x, y, z = chestBody:getPosition()
  pass:draw(box_model, x, y, z, 1, chestBody:getOrientation())

  -- Draw the lid
  x, y, z = lidBody:getPosition()
  pass:draw(box_lid_model, x, y, z, 1, lidBody:getOrientation())

  -- draw terrain
  pass:setShader(terrain_shader)
  pass:plane(0, 0, 0, 100, 100, -math.pi / 2, 1, 0, 0)
  pass:pop()
end


function lovr.draw(pass)
  render_shadow_map(render_scene)
  render_lighting_pass(render_scene)
  debug_passes(pass)

  return lovr.graphics.submit({ shadow_map_pass, lighting_pass, pass })
end
