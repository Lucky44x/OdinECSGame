package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

SNAPTYPE :: enum {
    Input = 0,
    Output,
    General
}

/*
    Factory Conveyor Component
*/
c_ConveyorSnapPoint :: struct {
    direction: f32,
    radius: f32,
    type: SNAPTYPE
}

t_ConveyorSnapPoint: ecs.Table(c_ConveyorSnapPoint)