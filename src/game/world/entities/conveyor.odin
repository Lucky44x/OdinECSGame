package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

import contextmenu "../../ui/contextmenu/items"

init_conveyor :: proc() {
    contextmenu.register_world_item({ 
        label = "Build Conveyor", 
        option = command_build_conveyor
    })
}

/*
Creates a conveyor entity and starts the placement logic
*/
create_conveyor :: proc(
    startPos: rl.Vector2
) -> ecs.entity_id {
    convEntity := create_entity(true)

    convCullable, _ := ecs.add_component(&comps.t_Cullable, convEntity)

    convTransform, _ := ecs.add_component(&comps.t_Transform, convEntity)
    convTransform.position = startPos
    convTransform.scale = { 1, 1 }

    convRenderer, _ := ecs.add_component(&comps.t_SplineRenderer, convEntity)
    convRenderer.startPoint = rl.Vector2{ 0, 0 }
    convRenderer.endPoint = rl.Vector2{ 0, 0 }
    convRenderer.controlPointStart = rl.Vector2{ 0, 0 }
    convRenderer.controlPointEnd = rl.Vector2{ 0, 0 }

    convRenderer.startDir = 0
    convRenderer.endDir = 0

    convRenderer.thickness = 75
    convRenderer.color = rl.DARKGRAY

    convBuilder, _ := ecs.add_component(&comps.t_ConveyorBuilder, convEntity)

    //Logistics Components will be added dynamically once conveyor is built

    //convLogisticIn, _ := ecs.add_component(&comps.t_LogisticIntake, convEntity)
    //convLogisticOutput, _ := ecs.add_component(&comps.t_LogisticOutput, convEntity)

    return convEntity
}   

@(private="file")
command_build_conveyor :: proc(
    mousePos: rl.Vector2
) {
    create_conveyor(mousePos)
    contextmenu.close_current_context_menu()
}