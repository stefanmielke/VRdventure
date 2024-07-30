local hands

local function get_models()
    return {
        left = 'assets/models/hand/left.glb',
        right = 'assets/models/hand/right.glb'
    }
end

local function load()
    local hand_paths = get_models()

    hand_models = {
        left = lovr.graphics.newModel(hand_paths.left),
        right = lovr.graphics.newModel(hand_paths.right)
    }
end

local function render(pass)
    for hand, model in pairs(hand_models) do
        if lovr.headset.isTracked(hand) then
            lovr.headset.animate(model)
            pass:draw(model, mat4(lovr.headset.getPose(hand)))
        end
    end
end

return {
    load = load,
    render = render,
}