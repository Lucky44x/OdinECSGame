package input

import rl "vendor:raylib"

Actions :: enum {
    Shoot = 0,
    ConfirmPlacement,
    DebugContextMenu
}

Axes :: enum {
    MovementVertical = 0,
    MovementHorizontal,
    ScrollVertical
}