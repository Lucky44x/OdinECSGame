package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Hashable Entity Component and Table
*/
c_HashableEntity :: struct{}

t_HashableEntity: ecs.Table(c_HashableEntity)