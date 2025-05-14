package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Guninput component and table
*/
c_GunInput :: struct {
    shootKey: rl.MouseButton
}

t_GunInput: ecs.Table(c_GunInput)