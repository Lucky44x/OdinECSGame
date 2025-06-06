package contextmenu

import "../../../../libs/clay"
import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"

ContextMenu :: struct {
    title: string,
    items: []ContextMenuItem
}

ContextMenuItem :: struct {
    label: string,
    option: ContextMenuOption
}

ContextMenuOption :: union {
    ContextMenu,
    ContextMenuCallback,
    ContextMenuPosCallback,
    ContextMenuECSCallback,
    ContextMenuBoolField,
    ContextMenuIntField,
    ContextMenuFloatField,
    ContextMenuVectorField,
}

ContextMenuCallback :: distinct proc()
ContextMenuPosCallback :: distinct proc(rl.Vector2)
ContextMenuECSCallback :: distinct proc(^ecs.Database, ecs.entity_id, rl.Vector2)
ContextMenuIntField :: distinct ^int
ContextMenuFloatField :: distinct ^f32
ContextMenuVectorField :: distinct ^rl.Vector2
ContextMenuBoolField :: distinct ^bool

SpawnMenu := ContextMenu {
    title = "Spawn",
    items = {
        {
            label = "Enemy",
            option = spawn_enemy
        }
    }
}

EmptyContextMenu := ContextMenu {
    title = "World",
    items = {
        {
            label = "Spawn",
            option = SpawnMenu
        }
    }
}

/**
    COMMANDS
*/
@(private="file")
spawn_enemy :: proc(
    menuPos: rl.Vector2
) {

}

/**
    STATE
*/
@(private="file")
current_menu: ^ContextMenu = nil
@(private="file")
menu_pos: rl.Vector2

init_context_menu :: proc() {

}

deinit_context_menu :: proc() {

}

update_context_menu :: proc() {

}

render_context_menu :: proc(
    menu: ^ContextMenu,
    offset: rl.Vector2
) {
    //TODO Implement
}

context_menu_draw :: proc() {
    if current_menu == nil do return

    render_context_menu(current_menu, menu_pos)
}

close_context_menu :: proc() {
    current_menu = nil
}