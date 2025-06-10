package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

import contextmenu "../../ui/contextmenu/items"

init_building :: proc() {
    contextmenu.register_world_item({ 
        label = "Build Conveyor", 
        option = command_build_building
    })
}

/*
Creates a conveyor entity and starts the placement logic
*/
create_building :: proc(
    startPos: rl.Vector2
) -> ecs.entity_id {
    buildEntity := create_entity(true)

    buildCullable, _ := ecs.add_component(&comps.t_Cullable, buildEntity)

    buildTransform, _ := ecs.add_component(&comps.t_Transform, buildEntity)
    buildTransform.position = startPos

    return buildEntity
}

@(private="file")
command_build_building :: proc(
    mousePos: rl.Vector2
) {
    create_conveyor(mousePos)
    contextmenu.close_current_context_menu()
}