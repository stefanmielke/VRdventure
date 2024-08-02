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
    deep_copy = deep_copy
}
