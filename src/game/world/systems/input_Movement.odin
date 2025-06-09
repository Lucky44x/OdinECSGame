package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "core:math/linalg"
import "../../../input"

@(private="file")
MOVEMENT_SCALAR :: 2

@(private="file")
v_movement_input: ecs.View
@(private="file")
it_movement_input: ecs.Iterator

@(private)
init_s_movement_input :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_movement_input, db, { &comp.t_Velocity, &comp.t_MovementStats, &comp.t_MovementInput })
    ecs.iterator_init(&it_movement_input, &v_movement_input)
}

/*
Handles movement Input and lerps the players velocity vector towards the desired movement vector
*/
s_movement_input :: proc(
    inputMap: ^input.ResolvedInputMap
) {
    for ecs.iterator_next(&it_movement_input) {
        eid := ecs.get_entity(&it_movement_input)

        if !check_is_active(eid) do continue

        velocity: ^comp.c_Velocity = ecs.get_component(&comp.t_Velocity, eid)
        stats: ^comp.c_MovementStats = ecs.get_component(&comp.t_MovementStats, eid)
        input_vec: rl.Vector2 = { 0,0 }


        input_vec[1] = inputMap.axes[input.Axes.MovementVertical]
        input_vec[0] = inputMap.axes[input.Axes.MovementHorizontal]

        input_vec_norm := rl.Vector2Normalize(input_vec)
        movement := input_vec_norm * stats.speed

        velocity.velocity = linalg.lerp(velocity.velocity, movement, rl.GetFrameTime() * stats.acceleration * MOVEMENT_SCALAR)
    }

    ecs.iterator_reset(&it_movement_input)
}