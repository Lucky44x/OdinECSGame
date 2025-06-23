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
v_factory_conv_update: ecs.View
@(private="file")
it_factory_conv_update: ecs.Iterator

@(private)
init_s_factory_conv_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_conv_update, db, { &comp.t_FactoryConveyor, &comp.t_LogisticIntake, &comp.t_LogisticOutput })
    ecs.iterator_init(&it_factory_conv_update, &v_factory_conv_update)
}

/*
Updates all conveyors
*/
s_factory_conv_update :: proc(_: rawptr) {
    profiling.profile_scope("Conveyor-Update System")

    for ecs.iterator_next(&it_factory_conv_update) {
        eid := ecs.get_entity(&it_factory_conv_update)
        if !check_is_active(eid) do continue

        conv: ^comp.c_FactoryConveyor = ecs.get_component(&comp.t_FactoryConveyor, eid)
        intake: ^comp.c_LogisticIntake = ecs.get_component(&comp.t_LogisticIntake, eid)

        //fmt.printfln("Conveyor has %i items and %i in intake", conv.itemQueue.count, intake.itemQueues[0].count)

        //If item present in intake slot
        if intake.itemQueues[0].count > 0 {
            enqErr := types.queue_enqueue(&conv.itemQueue, comp.ConveyorItem{
                item = intake.itemQueues[0].id,
                distance = 0
            })

            //If we successfully enqueed the item, we can decrement from the intake slot and continue to the next frame
            if enqErr == nil {
                intake.itemQueues[0].count -= 1
                if intake.itemQueues[0].count == 0 do intake.itemQueues[0].id = 0
            } else {
                fmt.printfln("ERROR !!! ERROR !!! ERROR : %e", enqErr)
            }
        }

        
        if conv.itemQueue.count == 0 do continue
        
        output: ^comp.c_LogisticOutput = ecs.get_component(&comp.t_LogisticOutput, eid)
        
        types.queue_foreach_ptr(&conv.itemQueue, proc(item: ^comp.ConveyorItem) {
            if item.distance >= 10 do return

            //TODO: Make this distance based and cache total length and arc-length of the spline
            //TODO: Make sure two items cannot hold the same position, basically, update from oldest to newest, if delta between last and current < some value do not update

            item.distance += rl.GetFrameTime()
        })

        //If our output slot is already used, block any other items from moving out of the queue for now
        //Basically just means that no other items will move into the output slot and only one will ever be inside the slot
        if output.itemQueues[0].count > 0 do continue

        oldestItem, _ := types.queue_peek(&conv.itemQueue)
        if oldestItem == nil do continue
        if oldestItem.distance < 10 do continue

        convItem, _ := types.queue_dequeue_ptr(&conv.itemQueue) //Dequeue from Conveyor
        if output.itemQueues[0].id == 0 do output.itemQueues[0].id = convItem.item  //Set Output Slot Item-Type if not already set
        if output.itemQueues[0].id != convItem.item do continue //Type mismatch -> skip

        output.itemQueues[0].count += 1 //Increment count of items in said output slot
        //Reset Distace
        convItem.distance = 0
        convItem.item = 0
    }

    ecs.iterator_reset(&it_factory_conv_update)
}