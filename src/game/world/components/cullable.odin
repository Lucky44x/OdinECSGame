package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Cullable component and Table
*/
c_Cullable :: struct{
    culled: bool
}

t_Cullable: ecs.Table(c_Cullable)