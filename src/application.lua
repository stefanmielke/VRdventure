local lighting_module = require 'lighting.simple_lighting'
local hands = require 'interaction.hands'
local motion = require 'locomotion.complex_motion'
local scene_manager = require 'scenes.scene_manager'

local config = require 'config'

local function debug_info()
    print('Device:', lovr.headset.getName())
end

local function load()
    debug_info()

    lighting_module.on_load()

    hands.load()

    scene_manager.set_next_scene(config.application.start_scene)
end

local function on_scene_change(initial_position)
    motion.reset(initial_position)
end

function lovr.keypressed(key, scancode, rep)
    if (key == 'b') then
        scene_manager.set_next_scene(config.application.start_scene) -- TODO: change this to be the current scene
        return
    end
    if (key == '0') then
        config.debug.show = not config.debug.show
    end
end

local function update(dt, world)
    if (lovr.headset.wasPressed('left', 'menu')) then
        lovr.event.quit()
        return
    end
    if (lovr.headset.wasPressed('right', 'b')) then
        config.debug.show = not config.debug.show
    end

    hands.update_model()
    motion.update(dt, world)

    scene_manager.update(dt, on_scene_change)

    motion.post_update(dt, world)
end

local function render_scene(pass)
    pass:push()

    pass:transform(mat4(motion.pose):invert())

    hands.render(pass);

    scene_manager.render(pass)

    pass:pop()
end

local function draw(pass)
    scene_manager.pre_render(pass)

    lighting_module.on_render(pass, render_scene)
end

return {
    load = load,
    update = update,
    draw = draw
}