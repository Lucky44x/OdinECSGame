package world

import ecs "../../../libs/ode_ecs"
import "../../../libs/jobs"
import rl "vendor:raylib"
import ctxmenu "../ui/contextmenu/items"

import "../../input"

import "core:fmt"

import "../profiling"

import "components"
import "systems"
import "entities"
import "partioning"

import "core:time"

/*
TODO: Implement some way to have different world descriptors
*/

global_player_transform_ref: ^components.c_Transform

ECS_WORLD: ecs.Database
WORLD_PARTITION: partioning.HashedPartionMap

TICK_TIME: f64 = 0.1
TICK_DELTA_ACCUMULATOR: f64 = 0

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
        250, 50, 5
    )

    global_player_transform_ref = ecs.get_component(&components.t_Transform, playerID)
    //ctxmenu.mouseOffset = &global_player_transform_ref.position
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
    profiling.profile_scope("World Update")

    //GameCamera.target = global_player_transform_ref.position - rl.Vector2{ f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2) }

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

    //Culling phase
    systems.s_cull_entities(CameraFrustum)

    profiling.profile_begin("Factory and Hash Jobs")
    factoryAndHashGroup: jobs.Group
    jobs.dispatch(.Medium, 
        jobs.make_job_noarg(&factoryAndHashGroup, run_hashing_systems),
        jobs.make_job_noarg(&factoryAndHashGroup, systems.s_factory_machine_update),
        jobs.make_job_noarg(&factoryAndHashGroup, systems.s_factory_conv_update)
    )
    jobs.wait(&factoryAndHashGroup)
    
    //Run the passthrough system and the slot cleanup after
    systems.s_factory_passthrough_update()
    systems.s_factory_slot_cleanup()

    profiling.profile_end()

    profiling.profile_begin("Factory Building and Boids Jobs")
    boidsAndBuildingGroup: jobs.Group
    jobs.dispatch(.Medium,
        jobs.make_job_typed(&boidsAndBuildingGroup, &systems.FactoryBuildArgs{inputMap, &WORLD_PARTITION}, systems.s_factory_build_conv),
        jobs.make_job_noarg(&boidsAndBuildingGroup, systems.s_boids_update),
        jobs.make_job_noarg(&boidsAndBuildingGroup, systems.s_factory_recipe_setter)
    )
    jobs.wait(&boidsAndBuildingGroup)

    profiling.profile_end()

    //When tick is needed, run another jobgroup, where the below code block is run in one, and logisticsUpdateOutput is run in the otherss

    //Velocity Application and transform phase
    systems.s_apply_velocity()
    systems.s_transform_lookat_target(GameCamera.target)
    systems.s_children_transform_update()

    //Rehash
    run_hashing_systems(nil)

    //Do Collision

    partioning.update_buckets(&WORLD_PARTITION)
    profiling.profile_end()
}

run_hashing_systems :: proc(_: rawptr) {
    //Hash + Boids
    partioning.clear_partition_data(&WORLD_PARTITION)
    systems.s_build_hash_partion(&WORLD_PARTITION)
}

run_factory_machine_updates :: proc(_: rawptr) {
    profiling.profile_begin("Machine Update - TID: ", fmt.tprintf("%i", jobs.current_thread_id()))

    time.sleep(2 * time.Millisecond)

    profiling.profile_end()
}

run_drawing_systems :: proc() {
    profiling.profile_scope("World Drawing")

    rl.BeginMode2D(GameCamera)

    systems.s_spline_renderer_render()  //Render Splines first (conveyors are renderer "behind" Sprites (buildings enemies etc.))
    systems.s_factory_render_conv_items(nil)
    systems.s_sprite_renderer_render()
    
    when ODIN_DEBUG {
        systems.s_draw_debug_selection_colliders()
        partioning.draw_bucket_map(&WORLD_PARTITION)
        systems.s_draw_debug_snappoints()
    }

    rl.EndMode2D()
}