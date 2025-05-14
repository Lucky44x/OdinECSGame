package world

import "components"
import "entities"
import "systems"

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
TODO: Implement some way to have different world descriptors
*/

ECS_WORLD: ecs.Database

init_world :: proc() {
    ecs.init(&ECS_WORLD, 5000)

    components.init_components(&ECS_WORLD, 5000)
    systems.init_systems(&ECS_WORLD)
}

run_update_systems :: proc() {
    //Update Camera
    camera_update()

    //Input phase
    systems.s_gun_input(
        GameCamera.offset,
        camera_shake,
        nil
    )
    systems.s_movementInput()

    //Culling phase
    systems.s_cull_entities(
        CameraFrustum
    )

    //Hash + Boids
    //TODO: IMPLEMENT

    //Transformation Phase
    systems.s_apply_velocity()
    systems.s_children_transform_update()
    systems.s_transform_lookat_target(
        GameCamera.target
    )

    //Rebuilding Hash Phase
    //TODO: IMPLEMENT

    //Collision Phase
    //TODO: IMPLEMENT
}

run_drawing_systems :: proc() {
    rl.BeginMode2D(GameCamera)

    systems.s_sprite_renderer_render()

    rl.EndMode2D()

    //TODO: Clear spatial partition Data at end of frame
}