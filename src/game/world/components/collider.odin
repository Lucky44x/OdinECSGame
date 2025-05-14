package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Collider Component and Table
*/

c_Collider :: struct{
    offX, offY, offW, offH: f32,
    rect: rl.Rectangle
}

t_Collider: ecs.Table(c_Collider)