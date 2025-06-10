package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

/*
    Factory Conveyor Builer "Tag" Component
*/
c_ConveyorBuilder :: struct { 
    _: u8
}

t_ConveyorBuilder: ecs.Table(c_ConveyorBuilder)