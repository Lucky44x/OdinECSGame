package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"
import "../tagging"
import "core:fmt"

import contextmenu "../../ui/contextmenu/items"

init_snappoint :: proc() {
    contextmenu.register_world_item({ 
        label = "Spawn Snappoint", 
        option = command_build_snappoint
    })
}

/*
Creates a conveyor entity and starts the placement logic
*/
create_snappoint :: proc(
    parent: ^comps.c_Transform,
    pos: rl.Vector2,
    rot: f32
) -> ecs.entity_id {
    snapEntity := create_entity(true)

    snapTransform, _ := ecs.add_component(&comps.t_Transform, snapEntity)

    snapTransformChild, _ := ecs.add_component(&comps.t_TransformChild, snapEntity)
    snapTransformChild.parent = parent
    snapTransformChild.offsetPosition = pos
    snapTransformChild.offsetRotation = rot

    fmt.printfln("Created snappoint: %s", snapTransformChild^)

    if parent == nil do snapTransform.position = pos

    snapPointComp, _ := ecs.add_component(&comps.t_ConveyorSnapPoint, snapEntity)
    snapPointComp.radius = 15

    snapPointTags, _ := ecs.add_component(&comps.t_Tags, snapEntity)
    snapPointTags ^= { tagging.EntityTags.SNAPPOINT }

    snapPointHashable, _ := ecs.add_component(&comps.t_HashableEntity, snapEntity)    

    return snapEntity
}   

@(private="file")
command_build_snappoint :: proc(
    mousePos: rl.Vector2
) {
    create_snappoint(nil, mousePos, 0)
    contextmenu.close_current_context_menu()
}