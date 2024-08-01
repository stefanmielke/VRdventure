local lighting_module = require 'lighting.simple_lighting'
local hands = require 'interaction.hands'
local motion = require 'locomotion.motion'
local scene_manager = require 'scenes.scene_manager'

local function debug_info()
    print('Device:', lovr.headset.getName())
end

function lovr.load()
    debug_info()

    lighting_module.on_load()

    hands.load()

    scene_manager.set_next_scene('test_scene')
end

local function on_scene_change(initial_position)
    motion.reset(initial_position)
end

function lovr.update(dt)
    if (lovr.headset.wasPressed('left', 'menu')) then
        lovr.event.quit()
        return
    end

    hands.update_model()
    motion.update(dt)

    scene_manager.update(dt, on_scene_change)
end

local function render_scene(pass)
    pass:push()

    pass:transform(mat4(motion.pose):invert())

    hands.render(pass);

    scene_manager.render(pass)

    pass:pop()
end

function lovr.draw(pass)
    scene_manager.pre_render(pass)

    lighting_module.on_render(pass, render_scene)
end
