package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "../../profiling"

@(private="file")
v_debug_inspectable: ecs.View
@(private="file")
it_debug_inspectable: ecs.Iterator

@(private)
init_s_debug_inspectables :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_debug_inspectable, db, { &comp.t_DebugInspectable, &comp.t_Transform })
    ecs.iterator_init(&it_debug_inspectable, &v_debug_inspectable)
}

/*
Gets the entity currently underneath the specified position
*/
s_debug_get_selected_inspectable :: proc(
    position: rl.Vector2
) -> (db: ^ecs.Database, eid: ecs.entity_id) {
    profiling.profile_scope("DebugInspector System")

    for ecs.iterator_next(&it_debug_inspectable) {
        eid := ecs.get_entity(&it_debug_inspectable)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        inspectable: ^comp.c_DebugInspectable = ecs.get_component(&comp.t_DebugInspectable, eid)
    
        checkRec := rl.Rectangle{
            transform.position[0] + (inspectable.collisionOffset[0] * transform.scale[0]),
            transform.position[1] + (inspectable.collisionOffset[1] * transform.scale[1]),
            inspectable.collisionSize[0],
            inspectable.collisionSize[1]
        }

        if rl.CheckCollisionPointRec(position, checkRec) {
            ecs.iterator_reset(&it_debug_inspectable)
            return v_debug_inspectable.db, eid
        }
    }

    fmt.printfln("None found");
    ecs.iterator_reset(&it_debug_inspectable)
    return nil, {}
}

/*
Draws the debug aabb around objects
*/
s_draw_debug_selection_colliders :: proc() {
    for ecs.iterator_next(&it_debug_inspectable) {
        eid := ecs.get_entity(&it_debug_inspectable)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        inspectable: ^comp.c_DebugInspectable = ecs.get_component(&comp.t_DebugInspectable, eid)

        checkRec := rl.Rectangle{
            transform.position[0] + (inspectable.collisionOffset[0] * transform.scale[0]),
            transform.position[1] + (inspectable.collisionOffset[1] * transform.scale[1]),
            inspectable.collisionSize[0],
            inspectable.collisionSize[1]
        }

        rl.DrawRectangleLinesEx(checkRec, 2, rl.DARKGREEN)
    }

    ecs.iterator_reset(&it_debug_inspectable)
}