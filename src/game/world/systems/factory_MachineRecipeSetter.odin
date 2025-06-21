package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "core:math/linalg"
import "../../profiling"
import "../../../input"
import "../partioning"
import "../entities"

@(private="file")
v_factory_recipe_setter: ecs.View
@(private="file")
it_factory_recipe_setter: ecs.Iterator

@(private)
init_s_factory_recipe_setter :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_recipe_setter, db, { &comp.t_FactoryMachine, &comp.t_RecipeSetter })
    ecs.iterator_init(&it_factory_recipe_setter, &v_factory_recipe_setter)
}

/*
Sets all Recipes
*/
s_factory_recipe_setter :: proc(_: rawptr) {
    profiling.profile_scope("Recipe-Setter System")

    for ecs.iterator_next(&it_factory_recipe_setter) {
        eid := ecs.get_entity(&it_factory_recipe_setter)
        if !check_is_active(eid) do continue
 
        machine: ^comp.c_FactoryMachine = ecs.get_component(&comp.t_FactoryMachine, eid)
        setter: ^comp.c_RecipeSetter = ecs.get_component(&comp.t_RecipeSetter, eid)

        machine.recipeID = setter.newRecipe
        machine.recipeRef = resource.GetRecipeByID(setter.newRecipe)

        //Sets all slots to their respective item-ids and resets their count
        for &slot, ind in machine.slots {
            slot.count = 0      //TODO: Far later -> Add items into player inventory
            slot.id = machine.recipeRef.inputs[ind].id
        }

        fmt.printfln("Set recipe on machine: %i to %i -> %s", eid, setter.newRecipe, machine.recipeRef^)

        //Remove Setter component when done
        ecs.remove_component(&comp.t_RecipeSetter, eid)
    }

    ecs.iterator_reset(&it_factory_recipe_setter)
}