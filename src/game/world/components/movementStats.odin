package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Movement Stats component and Table
*/

c_MovementStats :: struct {
    speed, acceleration: f32
}

t_MovementStats: ecs.Table(c_MovementStats)