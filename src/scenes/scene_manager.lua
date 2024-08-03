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

local json = require 'json.json'
local model = require 'model'
local grababble = require 'interaction.grababble'

local current_scene = {
    data = nil
}
local next_scene = {
    data = nil
}
local tracked_objects = {}

local function set_next_scene(name)
    next_scene.data = require('scenes.' .. name)
end

local function update(dt, on_new_scene_callback)
    if next_scene.data then
        print('Changing scene:', next_scene.data.name or 'no_name')

        if current_scene.data then
            current_scene.data.on_unload()
            tracked_objects = {}
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

local function add_tracked_object(object)
    table.insert(tracked_objects, object)
end

local function create_collider(world, mesh, x, y, z, extras_node)
    if extras_node.collision_type == 'sphere' then
        return world:newSphereCollider(x, y, z, extras_node.collision_size)
    elseif extras_node.collision_type == 'box' then
        return world:newBoxCollider(x, y, z, extras_node.collision_size, extras_node.collision_size, extras_node.collision_size)
    elseif extras_node.collision_type == 'convex' then
        return world:newConvexCollider(x, y, z, mesh)
    end

    return nil
end

local function create_grababble(collider, extras_node)
    if not extras_node.is_grababble then
        return
    end

    local settings = {}
    if extras_node.grab_type and extras_node.grab_type ~= '' then
        settings.grab_type = extras_node.grab_type
    end
    if extras_node.velocity_mult_on_release and extras_node.velocity_mult_on_release ~= '' then
        settings.velocity_mult_on_release = extras_node.velocity_mult_on_release
    end
    if extras_node.grab_joint and extras_node.grab_joint ~= '' then
        settings.grab_joint = extras_node.grab_joint
    end

    grababble.add_new_to_collider(collider, settings)
end

local function load_scene(world, path)
    local scene_model = lovr.graphics.newModel(path)
    local scene_json = json.decode(scene_model:getMetadata())

    local scene_meshes = model.get_meshes_from_model_nodes(scene_model)
    local i = 1
    for k, meshes_data in pairs(scene_meshes) do
        local meshes = {}
        for k2, mesh in pairs(meshes_data.meshes) do
            table.insert(meshes, mesh)
        end

        local extra_node = scene_json.nodes[i].extras
        if extra_node then
            if extra_node.collision_type and extra_node.collision_type ~= '' then
                local x, y, z = meshes_data.pose:getPosition()
                local collider = create_collider(world, nil, x, y, z, extra_node)
                if not collider then
                    break
                end

                create_grababble(collider, extra_node)
                model.add_to_collider(collider, meshes)
                add_tracked_object(collider)
            end
        end
        i = i + 1
    end
end

local function load_scene_static(world, path)
    local scene_model = lovr.graphics.newModel(path)

    local collider = world:newMeshCollider(scene_model)
    model.add_to_collider(collider, scene_model)
    add_tracked_object(collider)
end

local function load_scene_complete(world, scene_name)
    load_scene(world, 'assets/scenes/' .. scene_name .. '.glb')
    load_scene_static(world, 'assets/scenes/' .. scene_name .. '_static.glb')
end

return {
    set_next_scene = set_next_scene,
    update = update,
    pre_render = pre_render,
    render = render,
    add_tracked_object = add_tracked_object,
    load_scene = load_scene,
    load_scene_static = load_scene_static,
    load_scene_complete = load_scene_complete
}
