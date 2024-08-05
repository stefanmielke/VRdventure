-- all props:
-- {
--     collision = {
--         type = 'sphere',
--         size = 0.15,
--         grab = {
--             is_grababble = true,
--             type = 'physical',
--             joint = 'fixed',
--             velocity_mult_on_release = 1
--         }
--     }
-- }

return {
    apple = {
        collision = {
            type = 'sphere',
            size = 0.1,
            grab = {
                is_grababble = true,
                type = 'physical',
                joint = 'fixed',
                velocity_mult_on_release = 1
            }
        }
    },
    cabbage = {
        collision = {
            type = 'sphere',
            size = 0.15,
            grab = {
                is_grababble = true,
                type = 'physical',
                joint = 'fixed',
                velocity_mult_on_release = 1
            }
        }
    }
}
