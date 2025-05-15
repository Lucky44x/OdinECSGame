package world

import eng "../../../libs/engine"

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"

import comp "components"

/*
TODO: Implement some way to have different world descriptors
*/

ECS_WORLD: ecs.Database

init_world :: proc() {
    ecs.init(&ECS_WORLD, 5000)

    eng.init_engine(
        &ECS_WORLD,
        comp.deinit_components,
        5000,
        500 //TODO: Make smaller (number of systems)
    )


    comp.init_components()
}

run_update_systems :: proc() {
    //Update Camera
    camera_update()
}

run_drawing_systems :: proc() {
    rl.BeginMode2D(GameCamera)



    rl.EndMode2D()

    //TODO: Clear spatial partition Data at end of frame
}