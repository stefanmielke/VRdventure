local json = require 'json.json'
local model = require 'model'
local helper = require 'helper'
local grababble = require 'interaction.grababble'
local scene_manager = require 'scenes.scene_manager'

local function create_collider(world, mesh, x, y, z, extras_node)
    if extras_node.collision_type == 'sphere' then
        return world:newSphereCollider(x, y, z, extras_node.collision_size)
    elseif extras_node.collision_type == 'box' then
        return world:newBoxCollider(x, y, z, extras_node.collision_size, extras_node.collision_size,
            extras_node.collision_size)
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
    if not lovr.filesystem.isFile(path) then
        print('Load scene failed. File \'' .. path .. '\' not found')
        return
    end

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
                scene_manager.add_tracked_object(collider)
            end
        end
        i = i + 1
    end
end

local function load_scene_static(world, path)
    if not lovr.filesystem.isFile(path) then
        print('Load scene static failed. File \'' .. path .. '\' not found')
        return
    end

    local scene_model = lovr.graphics.newModel(path)

    local collider = world:newMeshCollider(scene_model)
    model.add_to_collider(collider, scene_model)
    scene_manager.add_tracked_object(collider)
end

local function load_scene_references(path)
    if not lovr.filesystem.isFile(path) then
        print('Load scene references failed. File \'' .. path .. '\' not found')
        return
    end

    local scene_model = lovr.graphics.newModel(path)

    local node_count = scene_model:getNodeCount()
    for i = 1, node_count, 1 do
        local node_name = scene_model:getNodeName(i)
        if node_name then
            local x, y, z, angle, ax, ay, az = scene_model:getNodePose(i)
            local math4 = lovr.math.newMat4()
            math4:set(x, y, z, angle, ax, ay, az)
            scene_manager.add_reference_object(node_name, { pose = math4 })
        end
    end
end

local function load_scene_complete_split_files(world, scene_name)
    load_scene(world, 'assets/scenes/' .. scene_name .. '.glb')
    load_scene_static(world, 'assets/scenes/' .. scene_name .. '_static.glb')
    load_scene_references('assets/scenes/' .. scene_name .. '_ref.glb')
end

local function load_static_models(world, scene_model, static_root_node_id)
    local static_node_ids = scene_model:getNodeChildren(static_root_node_id)
    for _, node_id in pairs(static_node_ids) do
        local node_name = scene_model:getNodeName(node_id)
        print(node_name)

        local scene_meshes = model.get_meshes_from_model_node_with_pose(scene_model, node_id)
        for _, scene_mesh in pairs(scene_meshes) do
            local collider = world:newCollider(0, 0, 0) -- TODO: see need for this to change

            for _, mesh in pairs(scene_mesh.meshes) do
                local vertices_table = mesh:getVertices(1, nil)
                local vertices = {}
                for _, v in pairs(vertices_table) do
                    table.insert(vertices, v[1])
                end

                collider:addShape(lovr.physics.newConvexShape(vertices, mesh:getIndices()))
                collider:setKinematic(true)
            end

            model.add_to_collider(collider, scene_mesh.meshes)
            scene_manager.add_tracked_object(collider)
        end
    end
end

local function load_dynamic_models(world, scene_model, static_root_node_id)
    local scene_json = json.decode(scene_model:getMetadata())
    local static_node_ids = scene_model:getNodeChildren(static_root_node_id)
    for _, node_id in pairs(static_node_ids) do
        local node_name = scene_model:getNodeName(node_id)
        local scene_meshes = model.get_meshes_from_model_node_with_pose(scene_model, node_id)
        
        local i = 1
        for _, scene_mesh in pairs(scene_meshes) do
            local meshes = {}
            for _, mesh in pairs(scene_mesh.meshes) do
                table.insert(meshes, mesh)
            end
            
            local extra_node = scene_json.nodes[i].extras
            if extra_node then
                if extra_node.collision_type and extra_node.collision_type ~= '' then
                    local x, y, z = scene_mesh.pose:getPosition()
                    local collider = create_collider(world, nil, x, y, z, extra_node)
                    if not collider then
                        break
                    end

                    create_grababble(collider, extra_node)
                    model.add_to_collider(collider, meshes)
                    scene_manager.add_tracked_object(collider)
                end
            end
        end
        i = i + 1
    end
end

local function load_references(world, scene_model, root_node_id)
    local static_node_ids = scene_model:getNodeChildren(root_node_id)
    for _, node_id in pairs(static_node_ids) do
        local node_name = scene_model:getNodeName(node_id)
        if node_name then
            local x, y, z, angle, ax, ay, az = scene_model:getNodePose(node_id)
            local math4 = lovr.math.newMat4()
            math4:set(x, y, z, angle, ax, ay, az)
            scene_manager.add_reference_object(node_name, { pose = math4 })
        end
    end
end

local function load_scene_complete_single_file(world, scene_name)
    local scene_model = lovr.graphics.newModel('assets/scenes/' .. scene_name .. '.glb')
    
    local root_node_id = scene_model:getRootNode()
    local children = scene_model:getNodeChildren(root_node_id)
    for _, index in pairs(children) do
        local node_name = scene_model:getNodeName(index)
        if node_name == 'Static' then
            load_static_models(world, scene_model, index)
        elseif node_name == 'Dynamic' then
            load_dynamic_models(world, scene_model, index)
        elseif node_name == 'References' then
            load_references(world, scene_model, index)
        end
    end
end

return {
    load_scene = load_scene,
    load_scene_static = load_scene_static,
    load_scene_references = load_scene_references,
    load_scene_complete_split_files = load_scene_complete_split_files,
    load_scene_complete_single_file = load_scene_complete_single_file
}
