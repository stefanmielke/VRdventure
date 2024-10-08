local config = {
    debug = {
        show = false
    },
    locomotion = {
        smooth_walk = true,
        smooth_turn = false,
        motion_direction = 'head',
        walk_stick = 'left',
        turn_stick = 'right'
    },
    input = {
        thumbstick_deadzone = 0.4
    },
    application = {
        start_scene = 'test_scene_single_model'
    }
}

return config
