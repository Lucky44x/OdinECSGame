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