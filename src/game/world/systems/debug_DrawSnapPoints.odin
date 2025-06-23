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
        passthrough: ^comp.c_LogisticPassthrough = ecs.get_component(&comp.t_LogisticPassthrough, eid)

        color := rl.Color{ 230, 41, 55, 125 }
        if passthrough.linkedInput == nil && passthrough.linkedOutput == nil do color = { 190, 33, 55, 255 } //Red -> Invalid State
        else if passthrough.linkedInput == nil do color = { 200, 122, 255, 125 } //Purple -> Output Node (Missing input)
        else if passthrough.linkedOutput == nil do color = { 0, 158, 47, 125 } //Green -> Input Node (Missing output)
        else do color = { 80, 80, 80, 125 } //Gray -> Filled Node

        rl.DrawCircleV(transform.position, snappoint.radius, color)
        vec2EndPos := transform.position
        vec2Dir := rl.Vector2Rotate({0, 1}, transform.rotation * rl.DEG2RAD)
        vec2Dir = rl.Vector2Normalize(vec2Dir)
        vec2EndPos += vec2Dir * snappoint.radius
        rl.DrawLineV(transform.position, vec2EndPos, rl.BLACK)

        if rl.CheckCollisionPointCircle(rl.GetMousePosition(), transform.position, snappoint.radius) {
            //Highlight linked transforms
            if passthrough.linkedInputTransform != nil do rl.DrawCircleLinesV(passthrough.linkedInputTransform.position, 25, rl.PINK)
            if passthrough.linkedOutputTransform != nil do rl.DrawCircleLinesV(passthrough.linkedOutputTransform.position, 25, rl.LIME)
        }
    }

    ecs.iterator_reset(&it_debug_snappoints)
}