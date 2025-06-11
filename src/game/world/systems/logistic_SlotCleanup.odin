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
v_factory_slot_cleanup: ecs.View
@(private="file")
it_factory_slot_cleanup: ecs.Iterator

@(private)
init_s_factory_slot_cleanup_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_slot_cleanup, db, { &comp.t_LogisticIntake, &comp.t_LogisticOutput })
    ecs.iterator_init(&it_factory_slot_cleanup, &v_factory_slot_cleanup)
}

/*
Cleanup system to set the itemType of empty slots to 0 -- (empty / NULL)
*/
s_factory_slot_cleanup :: proc() {
    profiling.profile_scope("Factory Slot cleanup System")

    for ecs.iterator_next(&it_factory_slot_cleanup) {
        eid := ecs.get_entity(&it_factory_slot_cleanup)

        if !check_is_active(eid) do continue

        intake: ^comp.c_LogisticIntake = ecs.get_component(&comp.t_LogisticIntake, eid)
        output: ^comp.c_LogisticOutput = ecs.get_component(&comp.t_LogisticOutput, eid)

        if intake.isValid {
            for i := 0; i < len(intake.itemQueues); i += 1 do if intake.itemQueues[i].count == 0 do intake.itemQueues[i].id = 0
        }

        if output.isValid {
            for i := 0; i < len(output.itemQueues); i += 1 do if output.itemQueues[i].count == 0 do output.itemQueues[i].id = 0
        }
    }

    ecs.iterator_reset(&it_factory_slot_cleanup)
}