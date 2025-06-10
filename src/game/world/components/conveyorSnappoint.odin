package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

//TODO: implement

/*
    Factory Conveyor Component
*/
c_ConveyorSnapPoint :: struct {
    direction: f32,
    radius: f32
}

t_ConveyorSnapPoint: ecs.Table(c_ConveyorSnapPoint)