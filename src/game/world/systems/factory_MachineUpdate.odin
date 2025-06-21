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
v_factory_machine_update: ecs.View
@(private="file")
it_factory_machine_update: ecs.Iterator

@(private)
init_s_factory_machine_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_machine_update, db, { &comp.t_FactoryMachine, &comp.t_LogisticIntake, &comp.t_LogisticOutput })
    ecs.iterator_init(&it_factory_machine_update, &v_factory_machine_update)
}

/*
Updates all machines and their progress
*/
s_factory_machine_update :: proc(_: rawptr) {
    profiling.profile_scope("Machine-Update System")

    for ecs.iterator_next(&it_factory_machine_update) {
        eid := ecs.get_entity(&it_factory_machine_update)
        if !check_is_active(eid) do continue

        machine: ^comp.c_FactoryMachine = ecs.get_component(&comp.t_FactoryMachine, eid)

        if machine.recipeRef == nil && machine.recipeID != 0 {
            //In this case the recipe was not correctly applied, so we add the setter
            setter, _ := ecs.add_component(&comp.t_RecipeSetter, eid)
            setter.newRecipe = machine.recipeID
            continue
        }
        //If Recipe ID 0 --> Recipe NULL so no operation needed
        if machine.recipeID == 0 do continue

        intake: ^comp.c_LogisticIntake = ecs.get_component(&comp.t_LogisticIntake, eid)
        output: ^comp.c_LogisticOutput = ecs.get_component(&comp.t_LogisticOutput, eid)

        //Check if all resources are satisfied
        hasResources := true
        for &slot, ind in machine.slots {
            if slot.id == 0 do continue

            //Check if the intake has resources and pull them in if yes
            for &intakeSlot in intake.itemQueues {
                if intakeSlot.id != slot.id || intakeSlot.count == 0 do continue
                
                slot.count += intakeSlot.count
                intakeSlot.count = 0
            }

            //When Done, Check if resources are not enough
            if slot.count < machine.recipeRef.inputs[ind].count {
                //If so set flag, and immediatly break out
                hasResources = false
                break
            }
        }

        if !hasResources {
            //When not enough resources are present, reset progress to 0 and continue
            machine.progress = 0
            continue
        }

        //If enough resources are present, increment progress by "item per tick" of the recipe
        machine.progress += machine.recipeRef.prodRatePerTick

        //If progress is greater euqal 1, add the output stacks into the output slots, esle just skip to the next machine
        if machine.progress < 1 do continue

        //Add the outputs into their respective slots on the output component
        machine.progress = 0
        for &stack, ind in machine.recipeRef.outputs {
            for &outStack in output.itemQueues {
                if outStack.id == 0 do outStack.id = stack.id
                if stack.id != outStack.id do continue

                outStack.count += stack.count
                break
            }
        }
    }

    ecs.iterator_reset(&it_factory_machine_update)
}