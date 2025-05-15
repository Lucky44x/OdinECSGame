package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    State Component and Table
*/

c_State :: bool

t_State: ecs.Table(c_State)