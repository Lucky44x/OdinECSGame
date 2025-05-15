package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    MovementStats component and Table
*/
c_MovementInput :: struct {
    forwardKey, backwardKey, leftKey, rightKey: rl.KeyboardKey
}

t_MovementInput: ecs.Table(c_MovementInput)