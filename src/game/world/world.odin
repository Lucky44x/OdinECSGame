package world

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"

import "../../input"

import "components"
import "systems"
import "entities"
import "partioning"

/*
TODO: Implement some way to have different world descriptors
*/

global_player_transform_ref: ^components.c_Transform

ECS_WORLD: ecs.Database
WORLD_PARTITION: partioning.HashedPartionMap

init_world :: proc() {
    ecs.init(&ECS_WORLD, 5000)
    partioning.init_spatial_hashing(
        &WORLD_PARTITION,
        512, 512,
        120
    )

    camera_init()

    components.init_components(&ECS_WORLD, 5000)
    systems.init_systems(&ECS_WORLD)
    entities.init_entities(&ECS_WORLD)

    playerID, _ := entities.create_player(
        {1280 / 2, 720 / 2},
        {25, 25},
        5, 50, 5
    )

    global_player_transform_ref = ecs.get_component(&components.t_Transform, playerID)
    entities.player_transform_ref = global_player_transform_ref
}

deinit_world :: proc() {
    entities.deinit_entities()
    ecs.terminate(&ECS_WORLD)
    partioning.deinit_spatial_partitioning(&WORLD_PARTITION)
}

run_update_systems :: proc(
    inputMap: ^input.ResolvedInputMap
) {
    //Update Camera
    camera_update()

    //Input phase
    systems.s_gun_input(
        inputMap,
        GameCamera.target,
        camera_shake_values,
        entities.spawn_bullet
    )

    systems.s_movement_input(inputMap)

    //Building input
    systems.s_factory_build_conv()

    //Culling phase
    systems.s_cull_entities(CameraFrustum)

    //Hash + Boids
    partioning.clear_partition_data(&WORLD_PARTITION)
    systems.s_build_hash_partion(&WORLD_PARTITION)

    //Velocity Application and transform phase
    systems.s_apply_velocity()
    systems.s_transform_lookat_target(GameCamera.target)
    systems.s_children_transform_update()

    //Rehash phase
    partioning.clear_partition_data(&WORLD_PARTITION)
    systems.s_build_hash_partion(&WORLD_PARTITION)

    //Collision and collision handle phase
    /*
    TODO: Implement Collision Systems
    s_collider_update()
    s_collision_checker()

    s_resolve_collisions()
    */

    partioning.update_buckets(&WORLD_PARTITION)
}

run_drawing_systems :: proc() {
    rl.BeginMode2D(GameCamera)

    systems.s_spline_renderer_render()  //Render Splines first (conveyors are renderer "behind" Sprites (buildings enemies etc.))
    systems.s_sprite_renderer_render()
    
    when ODIN_DEBUG {
        systems.s_draw_debug_selection_colliders()
        partioning.draw_bucket_map(&WORLD_PARTITION)
    }

    rl.EndMode2D()
}