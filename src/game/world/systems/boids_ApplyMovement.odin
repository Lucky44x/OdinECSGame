package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "core:math/linalg"
import "../../profiling"

@(private="file")
MOVEMENT_SCALAR_ENEMY :: 2

@(private="file")
v_boids_apply_movement: ecs.View
@(private="file")
it_boids_apply_movement: ecs.Iterator

@(private)
init_s_boids_apply_movement :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_boids_apply_movement, db, { &comp.t_BoidParticle, &comp.t_Velocity, &comp.t_MovementStats })
    ecs.iterator_init(&it_boids_apply_movement, &v_boids_apply_movement)
}

s_boids_apply_movement :: proc() {
    profiling.profile_scope("BoidsApply System")

    for ecs.iterator_next(&it_boids_apply_movement) {
        eid := ecs.get_entity(&it_boids_apply_movement)

        if !check_is_active(eid) do continue

        movementStats: ^comp.c_MovementStats = ecs.get_component(&comp.t_MovementStats, eid)
        boidParticle: ^comp.c_BoidParticle = ecs.get_component(&comp.t_BoidParticle, eid)
        velocity: ^comp.c_Velocity = ecs.get_component(&comp.t_Velocity, eid)

        movement := rl.Vector2ClampValue(boidParticle.steering_vector, -movementStats.speed, movementStats.speed) //* movementStats.speed

        //fmt.printfln("%v", boidParticle.steering_vector)

        velocity.velocity = linalg.lerp(velocity.velocity, movement, rl.GetFrameTime() * movementStats.acceleration * MOVEMENT_SCALAR_ENEMY)
    }

    ecs.iterator_reset(&it_boids_apply_movement)
}