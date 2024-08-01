local app = require 'application'

function lovr.load()
    app.load()
end

function lovr.update(dt)
    app.update(dt)
end

function lovr.draw(pass)
    app.draw(pass)
end
