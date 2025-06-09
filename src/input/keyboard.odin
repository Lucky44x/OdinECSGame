#+private
package input

import rl "vendor:raylib"

resolve_keyboard_action :: proc(
    action: rl.KeyboardKey
) -> ResolvedAction {
    if rl.IsKeyPressed(action) do return .Pressed
    if rl.IsKeyDown(action) do return .Down
    if rl.IsKeyReleased(action) do return .Released
    return .Up
}