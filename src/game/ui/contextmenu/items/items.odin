package contextmenuitems

import "../../../../../libs/clay"
import rl "vendor:raylib"
import ecs "../../../../../libs/ode_ecs"

import "core:fmt"

@(private="file")
MAX_CONTEXTMENU_ITEMS :: 256

ContextMenu :: struct {
    title: string,
    shouldClose: bool,
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
    ContextMenuECSPosCallback,
    ContextMenuBoolField,
    ContextMenuIntField,
    ContextMenuFloatField,
    ContextMenuVectorField,
}

ContextMenuCallback :: distinct proc()
ContextMenuPosCallback :: distinct proc(rl.Vector2)
ContextMenuECSPosCallback :: distinct proc(^ecs.Database, ecs.entity_id, rl.Vector2)
ContextMenuECSCallback :: distinct proc(^ecs.Database, ecs.entity_id)
ContextMenuIntField :: distinct ^int
ContextMenuFloatField :: distinct ^f32
ContextMenuVectorField :: distinct ^rl.Vector2
ContextMenuBoolField :: distinct ^bool

/**
World Context-Menu
*/
@(private = "file")
DynamicContextMenu :: struct {
    title: string,
    items: [dynamic]ContextMenuItem
}

@(private="file")
WorldSubMenus : map[string]^DynamicContextMenu = make(map[string]^DynamicContextMenu)

@(private="file")
WorldContextMenu : DynamicContextMenu = {
    title = "World",
    items  = make([dynamic]ContextMenuItem)
}

mouseOffset: ^rl.Vector2

register_world_item :: proc(
    item: ContextMenuItem
) {
    append(&WorldContextMenu.items, item)
}

register_world_submenu_item :: proc(
    subMenu: string,
    item: ContextMenuItem,
) {
    if subMenu not_in WorldSubMenus {
        WorldSubMenus[subMenu] = new(DynamicContextMenu)
        WorldSubMenus[subMenu].title = subMenu
        WorldSubMenus[subMenu].items = make([dynamic]ContextMenuItem)
    }

    append(&WorldSubMenus[subMenu].items, item)
}

makeWorldContextMenu :: proc() -> ^ContextMenu {
    currentMenuIsWorld = true
    current_ctx_menu = new(ContextMenu)
    current_ctx_menu.title = WorldContextMenu.title
    current_ctx_menu.items = make([]ContextMenuItem, len(WorldContextMenu.items) + len(WorldSubMenus) + 1)

    for item, ind in WorldContextMenu.items do current_ctx_menu.items[ind] = item

    //TODO: Implement sub menus

    current_ctx_menu.items[len(WorldContextMenu.items) + len(WorldSubMenus)] = { "Close", close_current_context_menu }

    return current_ctx_menu
}

@(private="file")
makeDynamicContextMenu :: proc(
    dConMenu: ^DynamicContextMenu
) -> ContextMenu {
    return ContextMenu {
        title = dConMenu.title,
        items = dConMenu.items[:]
    }
}

/**
    Import Cycle Shenanigans
*/

@(private="file")
current_ctx_menu: ^ContextMenu
@(private="file")
currentMenuIsWorld: bool
/**
    !!!!! IGNORE !!!!!

    IGNORE -- INTERNAL ONLY -- NOTHING WILL HAPPEN WHEN USED OUTSIDE OF INTERNAL CONTEXT

    !!!!! IGNORE !!!!!
*/
set_current_context_menu :: proc(
    ctx_menu: ^ContextMenu
) {
    current_ctx_menu = ctx_menu
}

close_current_context_menu :: proc() {
    current_ctx_menu.shouldClose = true
}

handle_cleanup :: proc() {
    if currentMenuIsWorld {
        delete(current_ctx_menu.items)
        free(current_ctx_menu)
        currentMenuIsWorld = false
    }
}