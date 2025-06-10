package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../tagging"

/*
    Hashable Entity Component and Table
*/
c_HashableEntity :: struct{
    _: u8
}

t_HashableEntity: ecs.Table(c_HashableEntity)