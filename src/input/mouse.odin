package input

import rl "vendor:raylib"

MouseAxis :: enum {
    MouseX,
    MouseY,
    ScrollX,
    ScrollY
}

@(private)
resolve_mouse_action :: proc(
    action: rl.MouseButton
) -> ResolvedAction {
    if rl.IsMouseButtonPressed(action) do return .Pressed
    if rl.IsMouseButtonPressed(action) do return .Down
    if rl.IsMouseButtonReleased(action) do return .Released
    return .Up
}

@(private)
resolve_mouse_axis :: proc(
    axis: MouseAxis
) -> ResolvedAxis {
    switch axis {
        case .MouseX: return rl.GetMouseDelta()[0]
        case .MouseY: return rl.GetMouseDelta()[1]
        case .ScrollX: return rl.GetMouseWheelMoveV()[0]
        case .ScrollY: return rl.GetMouseWheelMoveV()[1]
    }

    return 0
}