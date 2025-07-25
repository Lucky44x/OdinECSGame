package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"
import "../tagging"
import "core:fmt"

import contextmenu "../../ui/contextmenu/items"

init_snappoint :: proc() {

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

    linkedInTrans, linkedOutTrans: ^comps.c_Transform,

    type: comps.SNAPTYPE,
    pos: rl.Vector2,
    rot: f32
) -> ecs.entity_id {
    snapEntity := create_entity(true)

    snapTransform, _ := ecs.add_component(&comps.t_Transform, snapEntity)

    snapTransformChild, _ := ecs.add_component(&comps.t_TransformChild, snapEntity)
    snapTransformChild.parent = parent
    snapTransformChild.offsetPosition = pos
    snapTransformChild.offsetRotation = rot

    fmt.printfln("Created snappoint: %s with params: %s - %i -- %s - %i -- %e -- %v -- %f", snapTransformChild^, linkedInput, linkedInputslot, linkedOutput, linkedOutputSlot, type, pos, rot)

    if parent == nil do snapTransform.position = pos

    snapPointComp, _ := ecs.add_component(&comps.t_ConveyorSnapPoint, snapEntity)
    snapPointComp.radius = 15
    snapPointComp.type = type
    snapPointComp.direction = rot

    snapPointTags, _ := ecs.add_component(&comps.t_Tags, snapEntity)
    snapPointTags ^= { tagging.EntityTags.SNAPPOINT }

    snapPointHashable, _ := ecs.add_component(&comps.t_HashableEntity, snapEntity)    

    passthrough, _ := ecs.add_component(&comps.t_LogisticPassthrough, snapEntity)
    passthrough.linkedInputTransform = linkedInTrans
    passthrough.linkedOutputTransform = linkedOutTrans
    passthrough.linkedInput = linkedInput
    passthrough.linkedInputSlot = linkedInputslot
    passthrough.linkedOutput = linkedOutput
    passthrough.linkedOutputSlot = linkedOutputSlot

    fmt.printfln("Created snappoint logi passthrough: %s", passthrough^)

    return snapEntity
}