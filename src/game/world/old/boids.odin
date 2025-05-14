package world

import rl "vendor:raylib"
import ecs "../../../libs/ode_ecs"
import "core:fmt"

@(private="file") PERCEPTION_RADIUS :: 256
@(private="file") PLAYER_PERCEPTION_RADIUS :: 1024
@(private="file") SEPERATION_WEIGHT :: 2 
@(private="file") COHESION_WEIGHT :: 2
@(private="file") ALIGNMENT_WEIGHT :: 1
@(private="file") PLAYER_WEIGHT :: 0.25
//Components


//Views
@(private="file") v_Boids: ecs.View
@(private="file") it_Boids: ecs.Iterator

//Systems
s_do_boid_update :: proc() {
    for ecs.iterator_next(&it_Boids) {
        eid := ecs.get_entity(&it_Boids)

        state: ^c_State = ecs.get_component(&t_State, eid)
        if !state^ do continue

        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)
        boid: ^c_BoidParticle = ecs.get_component(&t_BoidParticle, eid)

        if boid.player_transform == nil {
            fmt.printfln("Error: player_transform for boid: %i was nil", eid)
        }

        boid.steering_vector = get_boid_velocity_vector(
            transform, boid.player_transform,
            PERCEPTION_RADIUS, PLAYER_PERCEPTION_RADIUS,
            SEPERATION_WEIGHT, COHESION_WEIGHT, ALIGNMENT_WEIGHT, PLAYER_WEIGHT
        )
    }

    ecs.iterator_reset(&it_Boids)
}

/*
Will initialize BOIDS specific components and systems
*/
init_comp_boids :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_BoidParticle, db, 5000)

    ecs.view_init(&v_Boids, db, {&t_BoidParticle, &t_Transform})
    ecs.iterator_init(&it_Boids, &v_Boids)
}