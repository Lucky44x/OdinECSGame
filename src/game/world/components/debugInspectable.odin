package components

import ecs "../../../../libs/ode_ecs"
import contextmenu "../../ui/contextmenu"
import rl "vendor:raylib"

c_DebugInspectable :: struct {
    contextMenu: ^contextmenu.ContextMenu,
    collisionSize, collisionOffset: rl.Vector2
}

t_DebugInspectable: ecs.Table(c_DebugInspectable)