package input

import rl "vendor:raylib"

InputActions :: enum {
    Shoot = 0,
    ConfirmPlacement,
    DebugMenu
}

InputAxes :: enum {
    MovementVertical = 0,
    MovementHorizontal
}