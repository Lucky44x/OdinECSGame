package world

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"

import "components"
import "systems"
import "entities"

/*
TODO: Implement some way to have different world descriptors
*/

ECS_WORLD: ecs.Database

init_world :: proc() {
    ecs.init(&ECS_WORLD, 5000)

    camera_init()

    components.init_components(&ECS_WORLD, 5000)
    systems.init_systems(&ECS_WORLD)
    entities.init_entities(&ECS_WORLD)

    entities.create_player(
        {1280 / 2, 720 / 2},
        {25, 25},
        5, 50, 5
    )

}

run_update_systems :: proc() {
    //Update Camera
    camera_update()

    //Input phase
    systems.s_gun_input(
        GameCamera.target,
        camera_shake_values,
        entities.spawn_bullet
    )
    systems.s_movement_input()

    //Culling phase
    systems.s_cull_entities(CameraFrustum)

    //Hash + Boids
    /*
    TODO: Implement Space Hashing
    s_hash_entity_positions()
    s_do_boid_update()
    */

    //Apply boid movement to velocity
    systems.s_boids_apply_movement()

    //Velocity Application and transform phase
    systems.s_apply_velocity()
    systems.s_transform_lookat_target(GameCamera.target)
    systems.s_children_transform_update()

    //Rehash phase
    /*
    TODO: Implement space hashing again
    clear_spatial_partition_data()
    s_hash_entity_positions()
    */

    //Collision and collision handle phase
    /*
    TODO: Implement Collision Systems
    s_collider_update()
    s_collision_checker()

    s_resolve_collisions()
    */
}

run_drawing_systems :: proc() {
    rl.BeginMode2D(GameCamera)

    systems.s_sprite_renderer_render()

    rl.EndMode2D()

    //TODO: Clear spatial partition Data at end of frame
}