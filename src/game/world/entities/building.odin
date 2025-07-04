package entities

import "core:fmt"

import "core:strings"

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

import contextmenu "../../ui/contextmenu/items"
import window "../../ui/window"
import "../../ui/fonts"

import "../../../../libs/clay"
import clayrl "../../../clay_render"

WindowSlotStyle : clay.TextElementConfig = {
    fontId = fonts.FONT_ID_BODY_16,
    fontSize = 16,
    textColor = clay.Color({ 200, 200, 200, 255 }),
    textAlignment = clay.TextAlignment.Center
}

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

    when ODIN_DEBUG {
        buildDebug, _ := ecs.add_component(&comps.t_DebugInspectable, buildEntity)
        buildDebug.collisionSize = buildTransform.scale
        buildDebug.collisionOffset = { -.5, -.5 }
        buildDebug.menu = contextmenu.ContextMenu {
            title = "Building",
            items = make([]contextmenu.ContextMenuItem, 2)           
        }
        buildDebug.menu.items[0] = contextmenu.ContextMenuItem {
            label = "Open Window",
            option = command_open_building_window
        }
        buildDebug.menu.items[1] = contextmenu.ContextMenuItem {
            label = "Close",
            option = proc(){ contextmenu.close_current_context_menu() }
        }
    }

    return buildEntity
}

@(private="file")
command_open_building_window :: proc(
    db: ^ecs.Database,
    eid: ecs.entity_id,
    mousePos: rl.Vector2,
) {
    building : ^comps.c_FactoryMachine = ecs.get_component(&comps.t_FactoryMachine, eid)
    output : ^comps.c_LogisticOutput = ecs.get_component(&comps.t_LogisticOutput, eid)

    ptr := window.AddWindow(window.UiWindow {
        title = strings.clone_from_cstring(building.descriptorRef.name),
        params = make([]rawptr, 2),
        offset = mousePos,
        constructor = proc(wind: ^window.UiWindow, params: []rawptr) {

            machine := window.GetWindowParams(comps.c_FactoryMachine, params[0])
            desc := machine.descriptorRef
            output := window.GetWindowParams(comps.c_LogisticIntake, params[1])

            if clay.UI()({
                id = clay.ID("machine_window_frame", wind.windowid),
                layout = {
                    sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                    childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                    layoutDirection = clay.LayoutDirection.LeftToRight,
                    padding = { 8, 8, 8, 8 },
                    childGap = 8
                }
            }) {
                if clay.UI()({
                    id = clay.ID("machine_window_inputs", wind.windowid),
                    layout = {
                        sizing = { width = clay.SizingFit({}), height = clay.SizingGrow({}) },
                        childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                        layoutDirection = clay.LayoutDirection.TopToBottom,
                        childGap = 8
                    },
                }) {
                    for i in 0..<len(desc.inputs) {
                        ui_building_slot(machine.slots[i])
                    }
                }

                if clay.UI()({
                    id = clay.ID("machine_window_buffer", wind.windowid),
                    layout = {
                        sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                        childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                        layoutDirection = clay.LayoutDirection.LeftToRight,
                        padding = { 8, 8, 8, 8 }
                    },
                }) {
                    if clay.UI()({
                        id = clay.ID("machine_window_buffer_task", wind.windowid),
                        layout = {
                            sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                            childAlignment = { x = clay.LayoutAlignmentX.Left, y = clay.LayoutAlignmentY.Center },
                            layoutDirection = clay.LayoutDirection.LeftToRight,
                        },
                        cornerRadius = { 5, 5, 5, 5 },
                        backgroundColor = clay.Color{ 65, 65, 65, 255 }
                    }) {
                        if clay.UI()({
                            id = clay.ID("machine_window_buffer_task_progress", wind.windowid),
                            layout = {
                                sizing = { width = clay.SizingPercent(machine.progress), height = clay.SizingGrow({}) },
                            },
                            cornerRadius = { 5, 5, 5, 5 },
                            backgroundColor = clay.Color{ 200, 200, 200, 255 },
                            clip = { true, true, {}}
                        }) {}
                    }
                }

                if clay.UI()({
                    id = clay.ID("machine_window_outputs", wind.windowid),
                    layout = {
                        sizing = { width = clay.SizingFit({}), height = clay.SizingGrow({}) },
                        childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                        layoutDirection = clay.LayoutDirection.TopToBottom,
                        childGap = 8
                    },
                }) {
                    for i in 0..<len(output.itemQueues) {
                        ui_building_slot(output.itemQueues[i])
                    }
                }
            }
        }
    })

    ptr.params[0] = rawptr(building)
    ptr.params[1] = rawptr(output)

    contextmenu.close_current_context_menu()
}

@(private="file")
ui_building_slot :: proc(
    stack: comps.LogisticStack
) {
    if clay.UI()({
        layout = {
            sizing = { width = clay.SizingFixed(32), height = clay.SizingFixed(32) },
            childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center }
        },
        backgroundColor = clay.Color{ 65, 65, 65, 255 },
        cornerRadius = { 5, 5, 5, 5 }
    }) {
        if stack.id == 0 do return //TODO: Implement NULL Item placeholder

        //Get Stack item type
        item := resource.GetItemByID(stack.id)
        src := item.sprite.source
        if type_of(src) != resource.TextureID do return //TODO: Implement other visuals
        srcID := src.(resource.TextureID)
        srcTex := resource.GetTextureByID(srcID)

        srcRec: rl.Rectangle
        srcRef: ^rl.Texture2D

        #partial switch &type in srcTex {
            case resource.SubTexture:
                srcRec = resource.get_src_rec(&type)
                source := resource.GetTextureByID(type.src)
                assert(type_of(source) == resource.TextureAtlas, "Source Texture was not an atlas")
                temp := source.(resource.TextureAtlas)
                srcRef = &temp.src
                break
            case rl.Texture2D:
                srcRec = resource.get_src_rec(&type)
                srcRef = &type
                break
        }
        data := new(clayrl.Raylib_Image, context.temp_allocator)
        data.src = srcRef
        data.rec = srcRec

        //Render Image
        if clay.UI()({
            layout = {
                sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
            },
            cornerRadius = { 5, 5, 5, 5 },
            image = { rawptr(&data) }
        }) {
            //clay.TextDynamic(fmt.tprintf("%i", stack.count), &WindowSlotStyle)
        }
    }
}

@(private="file")
ui_building_button :: proc(
    text: string
) -> bool {
    wasPressed := false

    if clay.UI()({
        id = clay.ID(text, 0),
        layout = {
            sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
            childAlignment = { x = clay.LayoutAlignmentX.Left, y = clay.LayoutAlignmentY.Center },
            layoutDirection = clay.LayoutDirection.LeftToRight
        },
        clip = { true, true, {} },
        cornerRadius = { 8, 8, 8, 8 }
    }) {
        backCol := clay.Color{ 65, 65, 65, 255 }
        if clay.Hovered() do backCol = clay.Color{ 95, 95, 95, 255 }

        if clay.UI()({
            id = clay.ID(text, 1),
            layout = {
                sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                layoutDirection = clay.LayoutDirection.LeftToRight,
                padding = { 8, 8, 8, 8 }
            },
            backgroundColor = backCol
        }) {
            if clay.Hovered() && rl.IsMouseButtonPressed(.LEFT) do wasPressed = true

            clay.TextDynamic(text, &WindowSlotStyle)
        }
    }

    return wasPressed
}

@(private="file")
command_build_building :: proc(
    mousePos: rl.Vector2
) {
    buildings := resource.GetBuildings()
    defer delete(buildings)

    posPtr := new(rl.Vector2)
    posPtr ^= mousePos

    ptr := window.AddWindow({
        title = "Choose Building",
        params = make([]rawptr, len(buildings) + 1),
        offset = mousePos,
        constructor = proc(wind: ^window.UiWindow, params: []rawptr) {
            spawnPos := window.GetWindowParams(rl.Vector2, params[0])

            if clay.UI()({
                id = clay.ID("building_window_list_frame", wind.windowid),
                layout = {
                    sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                    childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                    layoutDirection = clay.LayoutDirection.TopToBottom,
                    padding = { 8, 8, 8, 8 },
                    childGap = 8
                },
                clip = { true, true, clay.GetScrollOffset() }
            }) {
                for i in 1..<len(params) {
                    desc := window.GetWindowParams(resource.BuildingDescriptor, params[i])
                    if !ui_building_button(strings.clone_from_cstring(desc.name, context.temp_allocator)) do continue

                    wind.isOpen = false
                    create_building(spawnPos^, desc)
                }
            }
        },
        onClose = proc(){}
    })
    
    ptr.params[0] = rawptr(posPtr)
    for building, idx in buildings do ptr.params[idx + 1] = rawptr(building) 

    contextmenu.close_current_context_menu()
}