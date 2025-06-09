package input

import rl "vendor:raylib"

GamepadAction :: struct {
    gamepad: i32,
    button: rl.GamepadButton
}

GamepadAxis :: struct {
    gamepad: i32,
    axis: rl.GamepadAxis
}

@(private)
resolve_gamepad_action :: proc(
    action: GamepadAction
) -> ResolvedAction {
    if !rl.IsGamepadAvailable(action.gamepad) do return .Up

    if rl.IsGamepadButtonPressed(action.gamepad, action.button) do return .Pressed
    if rl.IsGamepadButtonDown(action.gamepad, action.button) do return .Down
    if rl.IsGamepadButtonReleased(action.gamepad, action.button) do return .Released
    return .Up
}

@(private)
resolve_gamepad_axis :: proc(
    mapping: GamepadAxis
) -> ResolvedAxis {
    if !rl.IsGamepadAvailable(mapping.gamepad) do return 0

    return rl.GetGamepadAxisMovement(mapping.gamepad, mapping.axis)
}