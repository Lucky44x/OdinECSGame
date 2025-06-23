package entities

import "core:fmt"

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

import contextmenu "../../ui/contextmenu/items"

init_building :: proc() {
    contextmenu.register_world_item({ 
        label = "Build Building", 
        option = command_build_building
    })
}

/*
Creates a building entity and starts the placement logic
*/
create_building :: proc(
    startPos: rl.Vector2,
    descriptor: ^resource.BuildingDescriptor
) -> ecs.entity_id {
    buildEntity := create_entity(true)

    buildCullable, _ := ecs.add_component(&comps.t_Cullable, buildEntity)

    buildTransform, _ := ecs.add_component(&comps.t_Transform, buildEntity)
    buildTransform.position = startPos

    buildSpriteRenderer, _ := ecs.add_component(&comps.t_SpriteRenderer, buildEntity)

    buildComp, _ := ecs.add_component(&comps.t_FactoryMachine, buildEntity)
    buildComp.descriptorRef = descriptor
    buildComp.recipeID = 0
    buildComp.recipeRef = resource.GetRecipeByID(0)    //Use NULL Recipe for start
    buildComp.slots = make([]resource.ItemStack, len(descriptor.inputs)) //Create slots for each input

    recipeSetter, _ := ecs.add_component(&comps.t_RecipeSetter, buildEntity)
    recipeSetter.newRecipe = descriptor.recipes[0]

    inputLen := len(descriptor.inputs)
    buildInput, _ := ecs.add_component(&comps.t_LogisticIntake, buildEntity)
    buildInput.itemQueues = make([]comps.LogisticStack, inputLen)
    buildInput.linkedPassthrough = make([]^comps.c_LogisticPassthrough, inputLen)

    for i : u8 = 0; i < u8(inputLen); i += 1 {
        create_snappoint(
            buildTransform, buildInput, i, nil, 0, buildTransform, nil, .Input, vec3ToVec2(descriptor.inputs[i], 0, 1), descriptor.inputs[i][2]
        )
    }

    outputLen := len(descriptor.outputs)
    buildOutput, _ := ecs.add_component(&comps.t_LogisticOutput, buildEntity)
    buildOutput.itemQueues = make([]comps.LogisticStack, outputLen)
    buildOutput.linkedPassthrough = make([]^comps.c_LogisticPassthrough, outputLen)

    for i : u8 = 0; i < u8(outputLen); i += 1 {
        create_snappoint(
            buildTransform, nil, 0, buildOutput, i, nil, buildTransform, .Output, vec3ToVec2(descriptor.outputs[i], 0, 1), descriptor.outputs[i][2]
        )
    }

    //TODO Bad code replace with deticated rederable parsing from json encoded data
    buildSpriteRenderer.sprite = resource.PrimitiveRect{}

    buildSpriteRenderer.color = descriptor.sprite.color
    buildTransform.origin = descriptor.sprite.origin
    buildTransform.scale = descriptor.sprite.scaling

    buildTransform.position = startPos

    return buildEntity
}

@(private="file")
command_build_building :: proc(
    mousePos: rl.Vector2
) {
    create_building(mousePos, resource.GetBuildingByID(1))
    contextmenu.close_current_context_menu()
}