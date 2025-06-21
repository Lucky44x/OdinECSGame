package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"
import "../../../resource"

/*
    Logistic Passthrough Component
*/
c_RecipeSetter :: struct {
    newRecipe: resource.RecipeID
}

t_RecipeSetter: ecs.Table(c_RecipeSetter)