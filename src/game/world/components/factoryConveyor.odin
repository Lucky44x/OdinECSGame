package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

@(private="file")
MAX_ITEMS_PER_CONV :: 2048

ConveyorItem :: struct {
    distance: f32,
    item: LogisticItem
}

/*
    Factory Conveyor Component
*/
c_FactoryConveyor :: struct {
    itemQueue: types.Queue(ConveyorItem, MAX_ITEMS_PER_CONV),
    speed: f32
}

t_FactoryConveyor: ecs.Table(c_FactoryConveyor)