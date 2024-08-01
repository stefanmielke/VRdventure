local current_scene = {
    data = nil
}
local next_scene = {
    data = nil
}

local function set_next_scene(name)
    next_scene.data = require('scenes.' .. name)
end

local function update(dt, on_new_scene_callback)
    if next_scene.data then
        io.write('Changing scene: \'', next_scene.data.name or 'no_name', '\'\n')

        if current_scene.data then
            current_scene.data.on_unload()
        end

        current_scene.data = next_scene.data
        next_scene.data = nil

        current_scene.data.on_load()

        if on_new_scene_callback then
            on_new_scene_callback(current_scene.data.initial_position)
        end
    end

    current_scene.data.on_update(dt)
end

local function pre_render(pass)
    current_scene.data.on_pre_render(pass)
end

local function render(pass)
    current_scene.data.on_render(pass)
end

return {
    set_next_scene = set_next_scene,
    update = update,
    pre_render = pre_render,
    render = render
}