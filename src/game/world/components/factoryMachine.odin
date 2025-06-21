package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"
import "../../../resource"

/*
    Factory Machine Struct
*/
c_FactoryMachine :: struct {
    descriptor: ^resource.BuildingDescriptor,
    recipe: ^resource.RecipeDescriptor
}

t_FactoryMachine: ecs.Table(c_FactoryMachine)