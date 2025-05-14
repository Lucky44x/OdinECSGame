package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Velocity Component and Table
*/
c_Velocity :: struct {
    velocity: rl.Vector2,
    angular_velocity: rl.Vector2,
    deceleration_coeff: f32
}

t_Velocity: ecs.Table(c_Velocity)