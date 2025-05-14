package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "core:fmt"

@(private="file")
v_boids_update: ecs.View
@(private="file")
it_boids_update: ecs.Iterator

@(private)
init_s_boids_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_boids_update, db, { &comp.t_BoidParticle, &comp.t_Transform })
    ecs.iterator_init(&it_boids_update, &v_boids_update)
}

s_boids_update :: proc() {
    for ecs.iterator_next(&it_boids_update) {
        eid := ecs.get_entity(&it_boids_update)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        boid: ^comp.c_BoidParticle = ecs.get_component(&comp.t_BoidParticle, eid)

        if boid.player_transform == nil {
            fmt.printfln("Error: player_transform for boid: %i was nil", eid)
        }

        // TODO: Implement Hash Structure again

        /*
        boid.steering_vector = get_boid_velocity_vector(
            transform, boid.player_transform,
            PERCEPTION_RADIUS, PLAYER_PERCEPTION_RADIUS,
            SEPERATION_WEIGHT, COHESION_WEIGHT, ALIGNMENT_WEIGHT, PLAYER_WEIGHT
        )
        */
    }

    ecs.iterator_reset(&it_boids_update)
}