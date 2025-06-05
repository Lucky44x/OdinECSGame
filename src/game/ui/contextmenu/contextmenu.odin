package contextmenu

import "../../../../libs/clay"
import rl "vendor:raylib"
import "core:fmt"
import "../../world/systems"
import ecs "../../../../libs/ode_ecs"

//TODO: MAKE ALL OF THIS DYNAMIC
/**

    Instead of hardcoding the options for the context menus, each entity should have a ContextMenuSelectable component which specifies the different
    Options the entity should provide

    More complex stuff could be achieved by allowing parameters through a ContextCallbackParam union for exmaple

    Allow for nested context menus via Uber-Union "ContextOption" which includes ContextMenu ([]ContextOption) again
    See chatgpt
**/

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

@(private)
ContextMenuEntityRecord :: struct {
    eid: ecs.entity_id,
    db: ^ecs.Database
}

@(private)
ContextMenuCommand :: struct {
    label: string,
    func: proc()
}

@(private)
MouseMenuPosition: clay.Vector2
@(private)
LastClickedEntity: ContextMenuEntityRecord

init_context_menus :: proc() {
    init_context_spawn_menu()
    init_context_inspector_menu()
}

deinit_context_menus :: proc() {
    deinit_context_spawn_menu()
    deinit_context_inspect_menu()
}

update_context_menus :: proc() {
    if rl.IsMouseButtonPressed(.RIGHT) {
        reset_open_states()
        MouseMenuPosition = transmute(clay.Vector2)rl.GetMousePosition()

        db, eid := systems.s_object_selection(MouseMenuPosition)
        LastClickedEntity = { eid, db }

        if db == nil do spawn_menu_open = true
        else do inspect_menu_open = true
    }
}

reset_open_states :: proc() {
    spawn_menu_open = false
    inspect_menu_open = false
}

render_context_menu_command :: proc(
    cmd: ContextMenuCommand,
    menuName: string,
    index: int
) {
    if clay.UI()({
        id = clay.ID(menuName, auto_cast index),
        layout = MENU_ITEM_LAYOUT,
        cornerRadius = { 5, 5, 5, 5 },
    }) {
        backColor: clay.Color = clay.Color({ 130, 130, 130, 125 })
        if clay.Hovered() {
            backColor[3] = 85

            if rl.IsMouseButtonPressed(.LEFT) {
                cmd.func()
            }
        }

        if clay.UI()({
            id = clay.ID("context-item-button-visual", auto_cast index),
            layout = MENU_BUTTON_LAYOUT,
            backgroundColor = backColor
        }) {
            clay.TextDynamic(
                cmd.label,
                clay.TextConfig({ fontSize = 16, textColor = clay.Color({ 255, 255, 255, 255 }), textAlignment = clay.TextAlignment.Center })
            )
        }
    }
}

