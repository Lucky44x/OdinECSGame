package spawnmenu

import "../../../../libs/clay"
import rl "vendor:raylib"
import "core:fmt"

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
ContextMenuCommand :: struct {
    label: string,
    func: proc()
}

@(private)
MouseMenuPosition: clay.Vector2

init_context_menus :: proc() {
    init_context_spawn_menu()
}

deinit_context_menus :: proc() {
    deinit_context_spawn_menu()
}

update_context_menus :: proc() {
    if rl.IsMouseButtonPressed(.RIGHT) {
        MouseMenuPosition = transmute(clay.Vector2)rl.GetMousePosition()

        spawn_menu_open = true
        //TODO: HANDLE DIFFERENT TYPES OF CONTEXT MENUS
    }
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

