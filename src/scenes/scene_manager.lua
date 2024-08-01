-- scene needs to have:
-- {
--     on_load = on_load, -- called when loading the scene
--     on_update = on_update, -- called once per frame (also called right after changing scenes). if it changes scenes, will call 'on_new_scene_callback' (if not nil) with 'initial_position'
--     on_pre_render = on_pre_render, -- called before rendering anything else (in case you need to render something before applying lighting, eg.: skybox)
--     on_render = on_render, -- called once per frame after 'on_pre_render'
--     on_unload = on_unload, -- called when unloading the scene (so you can unload resources)
--     initial_position = lovr.math.newMat4(), -- initial position for the player
--     name = 'Test Scene' -- name of the scene (optional)
-- }

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
        print('Changing scene:', next_scene.data.name or 'no_name')

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
