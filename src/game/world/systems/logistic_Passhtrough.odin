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
import types "../../../../libs/datatypes"

@(private="file")
v_factory_passthrough_update: ecs.View
@(private="file")
it_factory_passthrough_update: ecs.Iterator

@(private)
init_s_factory_passthrough_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_passthrough_update, db, { &comp.t_LogisticPassthrough })
    ecs.iterator_init(&it_factory_passthrough_update, &v_factory_passthrough_update)
}

/*
Updates the logistic passthroughs
*/
s_factory_passthrough_update :: proc() {
    profiling.profile_scope("Factory Passthrough Update")

    for ecs.iterator_next(&it_factory_passthrough_update) {
        eid := ecs.get_entity(&it_factory_passthrough_update)

        if !check_is_active(eid) do continue

        passthroughComp: ^comp.c_LogisticPassthrough = ecs.get_component(&comp.t_LogisticPassthrough, eid)
        if passthroughComp.linkedInput == nil || passthroughComp.linkedOutput == nil do continue //Only update passhtroughs that have full overage
       
        inputStack := &passthroughComp.linkedInput.itemQueues[passthroughComp.linkedInputSlot]
        outputStack := &passthroughComp.linkedOutput.itemQueues[passthroughComp.linkedOutputSlot]
        
        //If there isn't any item to move, skip
        if outputStack.count == 0 do continue 

        //If we have a type mismatch (because the input slot hasn't recieved any items) set the input slots id to the corresponding item
        if inputStack.id == 0 || inputStack.count == 0 do inputStack.id = outputStack.id

        //If we've got a type mismatch, skip this transfer
        if inputStack.id != outputStack.id do continue

        //Move one item from the output buffer to the input buffer
        outputStack.count -= 1
        inputStack.count += 1
        //The below is handled by it's own system
        //if outputStack.count == 0 do outputStack.id = 0 //If we moved ALL items in the linked output slot, set it's type to 0
    }

    ecs.iterator_reset(&it_factory_passthrough_update)
}