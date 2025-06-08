package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

@(private="file")
MAX_ITEMS_PER_CONV :: 2048

ConveyorItem :: struct {
    time: f32,
    id: string
}

/*
    Factory Conveyor Component
*/
c_FactoryConveyor :: struct {
}

t_FactoryConveyor: ecs.Table(c_FactoryConveyor)