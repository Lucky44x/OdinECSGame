package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "core:math/linalg"

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
    ecs.view_init(&v_movement_input, db, { &comp.t_Velocity, &comp.t_MovementInput, &comp.t_MovementStats })
    ecs.iterator_init(&it_movement_input, &v_movement_input)
}

/*
Handles movement Input and lerps the players velocity vector towards the desired movement vector
*/
s_movementInput :: proc() {
    for ecs.iterator_next(&it_movement_input) {
        eid := ecs.get_entity(&it_movement_input)

        if !check_is_active(eid) do continue

        velocity: ^comp.c_Velocity = ecs.get_component(&comp.t_Velocity, eid)
        input: ^comp.c_MovementInput = ecs.get_component(&comp.t_MovementInput, eid)
        stats: ^comp.c_MovementStats = ecs.get_component(&comp.t_MovementStats, eid)
        input_vec: rl.Vector2 = { 0,0 }


        if rl.IsKeyDown(input.forwardKey) {
            input_vec[1] = -1
        } else if rl.IsKeyDown(input.backwardKey) {
            input_vec[1] = 1
        }

        if rl.IsKeyDown(input.rightKey) {
            input_vec[0] = 1
        } else if rl.IsKeyDown(input.leftKey) {
            input_vec[0] = -1
        }

        input_vec_norm := rl.Vector2Normalize(input_vec)
        movement := input_vec_norm * stats.speed

        velocity.velocity = linalg.lerp(velocity.velocity, movement, rl.GetFrameTime() * stats.acceleration * MOVEMENT_SCALAR)
    }

    ecs.iterator_reset(&it_movement_input)
}