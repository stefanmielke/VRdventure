
local hand_models
local box_model

function lovr.load()
  hand_models = {
    left = lovr.graphics.newModel('assets/models/hand/left.glb'),
    right = lovr.graphics.newModel('assets/models/hand/right.glb')
  }

  box_model = lovr.graphics.newModel('assets/models/box.glb')
end

function lovr.update(dt)
  if (lovr.headset.wasPressed('left', 'menu')) then
    lovr.event.quit()
  end
end

function lovr.draw(pass)
  for hand, model in pairs(hand_models) do
    if lovr.headset.isTracked(hand) then
      lovr.headset.animate(model)
      pass:draw(model, mat4(lovr.headset.getPose(hand)))
    end
  end
end
