local config = require 'config'

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

local function get_meshes_from_model_nodes(model)
    local model_meshes = {}

    local node_count = model:getNodeCount()
    for i = 1, node_count, 1 do
        local node_name = model:getNodeName(i)
        print(node_name)
        if node_name then
            model_meshes[node_name] = get_meshes_from_model_node(model, i)
        end
    end

    return model_meshes
end

local function render_node_meshes(meshes, ...)
    
end

local function render_model_at_collider(pass, model, collider)
    local x, y, z = collider:getPosition()
    local a, ax, ay, az = collider:getOrientation()
    pass:draw(model, x, y, z, 1, a, ax, ay, az)

    if (config.debug.show) then
        pass:setColor(1, 0, 0, 1)
        pass:setWireframe(false)
        local minx, maxx, miny, maxy, minz, maxz = collider:getAABB()
        pass:line(minx, miny, minz, maxx, miny, minz, maxx, maxy, minz, minx, maxy, minz, minx, miny, minz)
        pass:line(minx, miny, maxz, maxx, miny, maxz, maxx, maxy, maxz, minx, maxy, maxz, minx, miny, maxz)
        pass:line(minx, miny, minz, minx, miny, maxz)
        pass:line(minx, maxy, minz, minx, maxy, maxz)
        pass:line(maxx, miny, minz, maxx, miny, maxz)
        pass:line(maxx, maxy, minz, maxx, maxy, maxz)
        pass:setWireframe(false)
        pass:setColor(1, 1, 1, 1)
    end
end

local function deep_copy(o, seen)
    seen = seen or {}
    if o == nil then
        return nil
    end
    if seen[o] then
        return seen[o]
    end

    local no
    if type(o) == 'table' then
        no = {}
        seen[o] = no

        for k, v in next, o, nil do
            no[deep_copy(k, seen)] = deep_copy(v, seen)
        end
        setmetatable(no, deep_copy(getmetatable(o), seen))
    else -- number, string, boolean, etc
        no = o
    end
    return no
end

return {
    get_meshes_from_model_node = get_meshes_from_model_node,
    get_meshes_from_model_nodes = get_meshes_from_model_nodes,
    render_model_at_collider = render_model_at_collider,
    deep_copy = deep_copy
}
