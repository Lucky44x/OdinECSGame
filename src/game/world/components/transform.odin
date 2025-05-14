package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Transform Component and Table
*/
c_Transform :: struct {
    position, scale, origin: rl.Vector2,
    rotation: f32
}

t_Transform: ecs.Table(c_Transform)