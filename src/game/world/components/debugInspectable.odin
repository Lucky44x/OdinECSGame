package components

import ecs "../../../../libs/ode_ecs"
import uiitems"../../ui/contextmenu/items"
import rl "vendor:raylib"

c_DebugInspectable :: struct {
    menu: ^uiitems.ContextMenu,
    collisionSize, collisionOffset: rl.Vector2
}

t_DebugInspectable: ecs.Table(c_DebugInspectable)