package contextmenu

import "../../../../libs/clay"
import rl "vendor:raylib"
import "core:fmt"
import ecs "../../../../libs/ode_ecs"

import "../inspector"

@(private="file")
inspect_menu_commands: [dynamic]ContextMenuCommand

@(private)
inspect_menu_open: bool

@(private)
init_context_inspector_menu :: proc() {
    inspect_menu_commands = make([dynamic]ContextMenuCommand)

    register_inspect_menu_command("Close", close_inspect_menu)
    register_inspect_menu_command("Delete", delete_entity)
    register_inspect_menu_command("Open Inspector", open_inspector)
}

@(private)
deinit_context_inspect_menu :: proc() {
    delete(inspect_menu_commands)
}

@(private="file")
close_inspect_menu :: proc() {
    inspect_menu_open = false
}

@(private="file")
open_inspector :: proc() {
    close_inspect_menu()
    if LastClickedEntity.db == nil do return

    inspector.open_inspector(
        LastClickedEntity.eid,
        LastClickedEntity.db
    )
}

@(private="file")
delete_entity :: proc() {
    close_inspect_menu()
    if LastClickedEntity.db == nil do return

    err := ecs.destroy_entity(LastClickedEntity.db,LastClickedEntity.eid)
    if err != nil do fmt.eprintfln("Error while deleting entity: %e", err)
}

register_inspect_menu_command :: proc(
    label: string,
    func: proc()
) {
    inject_at(&inspect_menu_commands, 0, ContextMenuCommand{
        label = label,
        func = func
    })
}

render_context_inspect_menu :: proc() {
    if !inspect_menu_open do return

    if clay.UI()({
        id = clay.ID("ContextInspectMenu"),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = { 8, 8, 8, 8 },
            childGap = 8,
            layoutDirection = clay.LayoutDirection.TopToBottom,
        },
        cornerRadius = {
            5, 5, 5, 5
        },
        floating = {
            offset = MouseMenuPosition,
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
        for cmd, ind in inspect_menu_commands do render_context_menu_command(cmd, "context-menu-spawn", ind)
    }
}