local config = require 'config'

-- model can be a model or a mesh
local function add_to_collider(collider, model)
    local current_data = collider:getUserData()
    if not current_data then
        current_data = {}
    end
    current_data.model = model

    collider:setUserData(current_data)
end

local function get_meshes_from_model_node(model, index)
    local model_data = model:getData()

    local meshes = {}
    local meshes_indexes = model_data:getNodeMeshes(index)
    for k, v in pairs(meshes_indexes) do
        local mesh = model:getMesh(v)
        table.insert(meshes, mesh)
    end

    return meshes
end

local function get_meshes_from_model_node_with_pose(model, index)
    local model_meshes = {}

    local node_name = model:getNodeName(index)
    if node_name then
        local x, y, z, angle, ax, ay, az = model:getNodePose(index)
        local math4 = lovr.math.newMat4()
        math4:set(x, y, z, angle, ax, ay, az)
        model_meshes[node_name] = {
            pose = math4,
            meshes = get_meshes_from_model_node(model, index)
        }
    end

    return model_meshes
end

local function get_meshes_from_model_nodes(model)
    local model_meshes = {}

    local node_count = model:getNodeCount()
    for i = 1, node_count, 1 do
        local node_name = model:getNodeName(i)
        if node_name then
            local x, y, z, angle, ax, ay, az = model:getNodePose(i)
            local math4 = lovr.math.newMat4()
            math4:set(x, y, z, angle, ax, ay, az)
            model_meshes[node_name] = {
                pose = math4,
                meshes = get_meshes_from_model_node(model, i)
            }
        end
    end

    return model_meshes
end

local function render_model_at_collider(pass, model, collider)
    if model then
        local x, y, z = collider:getPosition()
        local a, ax, ay, az = collider:getOrientation()
        pass:draw(model, x, y, z, 1, a, ax, ay, az)
    end

    if (config.debug.show) then
        pass:setColor(1, 0, 0, 0.1)
        pass:setWireframe(true)
        for _, v in pairs(collider:getShapes()) do
            local type = v:getType()
            if type == 'box' then
                local x, y, z = v:getPosition()
                local angle, ax, ay, az = v:getOrientation()
                local width, height, depth = v:getDimensions()
                pass:box(x, y, z, width, height, depth, angle, ax, ay, az, 'line')
            elseif type == 'sphere' then
                local x, y, z = v:getPosition()
                local angle, ax, ay, az = v:getOrientation()
                pass:sphere(x, y, z, v:getRadius(), angle, ax, ay, az)
            elseif type == 'capsule' then
                local x, y, z = v:getPosition()
                local angle, ax, ay, az = v:getOrientation()
                pass:capsule(x, y, z, v:getRadius(), v:getLength(), angle, ax, ay, az)
            elseif type == 'cylinder' then
                local x, y, z = v:getPosition()
                local angle, ax, ay, az = v:getOrientation()
                pass:cylinder(x, y, z, v:getRadius(), v:getLength(), angle, ax, ay, az)
            end
        end
        pass:setWireframe(false)
        pass:setColor(1, 1, 1, 1)
    end
end

local function render_model_collider(pass, collider)
    local current_data = collider:getUserData()
    if not current_data then
        return
    end

    if type(current_data.model) == 'table' then
        for _, m in pairs(current_data.model) do
            render_model_at_collider(pass, m, collider)
        end
    else
        render_model_at_collider(pass, current_data.model, collider)
    end
end

local function render_all_model_from_colliders(pass, world)
    local all_colliders = world:getColliders()
    for _, v in pairs(all_colliders) do
        render_model_collider(pass, v)
    end
end

return {
    add_to_collider = add_to_collider,
    get_meshes_from_model_node = get_meshes_from_model_node,
    get_meshes_from_model_node_with_pose = get_meshes_from_model_node_with_pose,
    get_meshes_from_model_nodes = get_meshes_from_model_nodes,
    render_model_at_collider = render_model_at_collider,
    render_model_collider = render_model_collider,
    render_all_model_from_colliders = render_all_model_from_colliders
}
