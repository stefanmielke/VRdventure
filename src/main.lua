local lighting_module = require 'lighting'
local hands_module = require 'hands'

motion = require 'motion'

local current_scene

local function debug_info()
    io.write('Device: ', lovr.headset.getName(), '\n')
end

function lovr.load()
    debug_info()

    lighting_module.on_load()

    hands_module.load()

    next_scene = require 'scenes.test_scene'
end

function lovr.update(dt)
    if next_scene then
        io.write('Changing scene: \'', next_scene.name or 'no_name', '\'\n')

        if current_scene then
            current_scene.on_unload()
        end

        current_scene = next_scene
        next_scene = nil

        current_scene.on_load(motion.pose)

        motion.reset(current_scene.initial_position)
    end

    if (lovr.headset.wasPressed('left', 'menu')) then
        lovr.event.quit()
        return
    end

    motion.update(dt)

    current_scene.on_update(dt)
end

local function render_scene(pass)
    pass:push()

    pass:transform(mat4(motion.pose):invert())

    hands_module.render(pass, mat4(motion.pose));

    current_scene.on_render(pass)

    pass:pop()
end

function lovr.draw(pass)
    current_scene.on_pre_render(pass)

    lighting_module.on_render(pass, render_scene)
end
