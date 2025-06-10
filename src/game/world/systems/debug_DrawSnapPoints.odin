package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "../../profiling"

@(private="file")
v_debug_snappoints: ecs.View
@(private="file")
it_debug_snappoints: ecs.Iterator

@(private)
init_s_debug_draw_snappoints :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_debug_snappoints, db, { &comp.t_ConveyorSnapPoint, &comp.t_Transform })
    ecs.iterator_init(&it_debug_snappoints, &v_debug_snappoints)
}

/*
Draws the snapping range of the snappoints
*/
s_draw_debug_snappoints :: proc() {
    for ecs.iterator_next(&it_debug_snappoints) {
        eid := ecs.get_entity(&it_debug_snappoints)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        snappoint: ^comp.c_ConveyorSnapPoint = ecs.get_component(&comp.t_ConveyorSnapPoint, eid)
        
        rl.DrawCircleV(transform.position, snappoint.radius, rl.Color{ 0, 158, 47, 125 })
    }

    ecs.iterator_reset(&it_debug_snappoints)
}