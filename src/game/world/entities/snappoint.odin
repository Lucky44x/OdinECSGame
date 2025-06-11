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
    linkedInput: ^comps.c_LogisticIntake,
    linkedInputslot: u8,
    linkedOutput: ^comps.c_LogisticOutput,
    linkedOutputSlot: u8,
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

    passthrough, _ := ecs.add_component(&comps.t_LogisticPassthrough, snapEntity)
    passthrough.linkedInput = linkedInput
    passthrough.linkedInputSlot = linkedInputslot
    passthrough.linkedOutput = linkedOutput
    passthrough.linkedOutputSlot = linkedOutputSlot

    return snapEntity
}   

@(private="file")
command_build_snappoint :: proc(
    mousePos: rl.Vector2
) {
    create_snappoint(nil, nil, 0, nil, 0, mousePos, 0)
    contextmenu.close_current_context_menu()
}