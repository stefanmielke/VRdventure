local lighting_module = require 'lighting'
local hands_module = require 'hands'

local current_scene

function lovr.load()
  lighting_module.on_load()

  hands_module.load();

  current_scene = require 'scenes.test_scene'
  current_scene.on_load()
end

function lovr.update(dt)
  if (lovr.headset.wasPressed('left', 'menu')) then
    lovr.event.quit()
    return
  end

  current_scene.on_update(dt)
end

local function render_scene(pass)
  pass:push()

  hands_module.render(pass);

  current_scene.on_render(pass)

  pass:pop()
end

function lovr.draw(pass)
  lighting_module.on_render(pass, render_scene)
end
