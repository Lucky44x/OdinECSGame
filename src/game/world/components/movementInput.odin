package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Tags a component as movable
*/
c_MovementInput :: struct {}

t_MovementInput: ecs.Table(c_MovementInput)