package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"
import "../../../resource"

/*
    Factory Machine Struct
*/
c_FactoryMachine :: struct {
    descriptorRef: ^resource.BuildingDescriptor,
    recipeID: resource.RecipeID,
    recipeRef: ^resource.RecipeDescriptor,
    progress: f32,
    slots: []LogisticStack
}

t_FactoryMachine: ecs.Table(c_FactoryMachine)