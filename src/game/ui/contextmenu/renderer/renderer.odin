package contextmenurenderer

import "../../../../../libs/clay"
import rl "vendor:raylib"
import ecs "../../../../../libs/ode_ecs"
import "../../../world/systems"
import comps "../../../world/components"
import "../items"
import "../../fonts"

import "core:fmt"

@(private="file")
CallbackParams :: struct {
    db: ^ecs.Database,
    eid: ecs.entity_id,
    pos: rl.Vector2,
}

/**
    STATE
*/
@(private="file")
current_menu: ^items.ContextMenu = nil
@(private="file")
current_callback_params: CallbackParams
@(private="file")
menu_pos: rl.Vector2

/**
    LAYOUT
*/
@(private="file")
MENU_ITEM_LAYOUT := clay.LayoutConfig{
    sizing = {
        width = clay.SizingGrow({}),
        height = clay.SizingGrow({})
    },
    childAlignment = {
        clay.LayoutAlignmentX.Center,
        clay.LayoutAlignmentY.Center
    }
}

@(private="file")
MENU_BUTTON_LAYOUT := clay.LayoutConfig{
    sizing = {
        width = clay.SizingGrow({}),
        height = clay.SizingGrow({})
    },
    padding = {
        8, 8, 8, 8
    },
    childAlignment = {
        clay.LayoutAlignmentX.Center,
        clay.LayoutAlignmentY.Center
    }
}

init_context_menu :: proc() {

}

deinit_context_menu :: proc() {
    items.handle_cleanup()
}

update_context_menu :: proc() {
    if rl.IsMouseButtonPressed(.RIGHT) {
        if current_menu != nil do close_context_menu()

        db, eid := systems.s_debug_get_selected_inspectable(rl.GetMousePosition())
        menu_pos = rl.GetMousePosition()
        current_callback_params = { db, eid, menu_pos }

        if db == nil do current_menu = items.makeWorldContextMenu() //No Entity clicked
        else {
            //Entity was clicked
            inspectable: ^comps.c_DebugInspectable = ecs.get_component(&comps.t_DebugInspectable, eid)
            current_menu = &inspectable.menu
            fmt.printfln("%s", current_menu^)
        }

        assert(current_menu != nil, "Error: Contextmenu was nil, illegal state")
        current_menu.shouldClose = false
        items.set_current_context_menu(current_menu)
    }
}

render_context_menu :: proc(
    menu: ^items.ContextMenu,
    offset: rl.Vector2
) {
    if menu.shouldClose {
        //Close menu and return
        close_context_menu()
        return
    }

    //Begin general Layout
    if clay.UI()({
        id = clay.ID(menu.title),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = { 8, 8, 8, 8 },
            childGap = 8,
            layoutDirection = clay.LayoutDirection.TopToBottom
        },
        cornerRadius = { 5, 5, 5, 5 },
        floating = {
            offset = offset,
            expand = {},
            attachment = {
                element = clay.FloatingAttachPointType.LeftTop,
                parent = clay.FloatingAttachPointType.LeftTop
            },
            zIndex = 10,
            attachTo = clay.FloatingAttachToElement.Root,
            clipTo = clay.FloatingClipToElement.None,
            pointerCaptureMode = clay.PointerCaptureMode.Capture
        },
        backgroundColor = clay.Color({ 80, 80, 80, 255 })
    }) {
        //Render Title
        clay.TextDynamic(menu.title, clay.TextConfig({
            fontId = fonts.FONT_ID_TITLE_32,
            fontSize = 32,
            textColor = clay.Color({ 200, 200, 200, 255 }),
            textAlignment = clay.TextAlignment.Center
        }))

        for &item, ind in menu.items do render_context_menu_item(&item, ind, current_callback_params)
    }
}

render_context_menu_item :: proc(
    item: ^items.ContextMenuItem,
    index: int,
    callbackParams: CallbackParams
) {
    //fmt.printfln("Rendering Item: %i - %s - %s", index, item.label, item.option)
    if item.option == nil do return

    switch type in item.option {
        case items.ContextMenuCallback:
            render_context_menu_button(item, current_callback_params)
            break
        case items.ContextMenuECSCallback:
            render_context_menu_button(item, current_callback_params)
            break
        case items.ContextMenuPosCallback:        
            render_context_menu_button(item, current_callback_params)
            break
        case items.ContextMenuECSPosCallback:
            render_context_menu_button(item, current_callback_params)
            break
        
        case items.ContextMenuBoolField:
            break
        case items.ContextMenuFloatField:
            break
        case items.ContextMenuIntField:
            break
        case items.ContextMenuVectorField:
            break
        
        case items.ContextMenu:
            break
    }
}

//TODO: Implement all the other field types

render_context_menu_float_field :: proc(
    item: ^items.ContextMenuFloatField
) {

}

render_context_menu_button :: proc(
    item: ^items.ContextMenuItem,
    params: CallbackParams
) {
    //fmt.printfln("Rendering button: %s", item.label)

    if clay.UI()({
        id = clay.ID(item.label),
        layout = MENU_ITEM_LAYOUT,
        cornerRadius = { 5, 5, 5, 5 }
    }) {
        backColor: clay.Color = clay.Color({ 130, 130, 130, 125 })
        if clay.Hovered() {
            backColor[3] = 85

            if rl.IsMouseButtonPressed(.LEFT) {
                #partial switch type in item.option {
                    case items.ContextMenuCallback: type(); break
                    case items.ContextMenuECSCallback: type(params.db, params.eid); break
                    case items.ContextMenuPosCallback: type(params.pos); break
                    case items.ContextMenuECSPosCallback: type(params.db, params.eid, params.pos); break
                }
            }
        }

        if clay.UI()({
            id = clay.ID(item.label, 1),
            layout = MENU_BUTTON_LAYOUT,
            backgroundColor = backColor
        }) {
            clay.TextDynamic(
                item.label,
                clay.TextConfig({
                    fontSize = 16,
                    textColor = clay.Color({ 255, 255, 255, 255 }),
                    textAlignment = clay.TextAlignment.Center
                })
            )
        }
    }
}

context_menu_draw :: proc() {
    if current_menu == nil do return

    render_context_menu(current_menu, menu_pos)
}

close_context_menu :: proc() {
        current_menu = nil
        items.handle_cleanup()
        items.set_current_context_menu(current_menu)
}