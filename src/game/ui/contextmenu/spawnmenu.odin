package contextmenu

import "../../../../libs/clay"
import rl "vendor:raylib"
import "../../world/entities"
import "../../world"

@(private="file")
spawn_menu_commands: [dynamic]ContextMenuCommand

@(private)
spawn_menu_open: bool

@(private)
init_context_spawn_menu :: proc() {
    spawn_menu_commands = make([dynamic]ContextMenuCommand)

    register_spawn_menu_command("Close", close_spawn_menu)
    register_spawn_menu_command("Spawn Enemy", spawn_enemy)
}

@(private)
deinit_context_spawn_menu :: proc() {
    delete(spawn_menu_commands)
}

@(private="file")
close_spawn_menu :: proc() {
    spawn_menu_open = false
}

@(private="file")
spawn_enemy :: proc() {
    entities.spawn_enemy(MouseMenuPosition, { 15, 15 }, world.global_player_transform_ref)
    close_spawn_menu()
}

register_spawn_menu_command :: proc(
    label: string,
    func: proc()
) {
    inject_at(&spawn_menu_commands, 0, ContextMenuCommand{
        label = label,
        func = func
    })
}

render_context_spawn_menu :: proc() {
    if !spawn_menu_open do return

    if clay.UI()({
        id = clay.ID("ContextSpawnMenu"),
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
        for cmd, ind in spawn_menu_commands do render_context_menu_command(cmd, "context-menu-spawn", ind)
    }
}