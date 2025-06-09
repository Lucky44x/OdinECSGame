package input

import rl "vendor:raylib"

ActionMapping :: union {
    rl.KeyboardKey,
    rl.MouseButton,
    GamepadAction
}

AxisMapping :: union {
    VirtualAxis,
    GamepadAxis,
    MouseAxis
}

VirtualAxis :: struct {
    positive, negative: ActionMapping
}

ResolvedAction :: enum {
    Pressed,
    Released,
    Down,
    Up
}

ResolvedAxis :: f32

InputMap :: struct {
    actions: [Actions]ActionMapping,
    axes: [Axes]AxisMapping
}

ResolvedInputMap :: struct {
    actions: [Actions]ResolvedAction,
    axes: [Axes]ResolvedAxis
}

resolve_input_map :: proc(
    self: ^InputMap
) -> ResolvedInputMap {
    finalMap: ResolvedInputMap

    for mapping, ind in self.actions {
        finalMap.actions[ind] = #force_inline resolve_action(mapping)
    }

    for mapping, ind in self.axes {
        finalMap.axes[ind] = #force_inline resolve_axis(mapping)
    }

    return finalMap
}

@(private)
resolve_action :: proc(
    mapping: ActionMapping
) -> ResolvedAction {
    switch action in mapping {
        case GamepadAction: return #force_inline resolve_gamepad_action(action)
        case rl.KeyboardKey: return #force_inline resolve_keyboard_action(action)
        case rl.MouseButton: return #force_inline resolve_mouse_action(action)
    }

    return .Up
}

@(private)
resolve_axis :: proc(
    mapping: AxisMapping
) -> ResolvedAxis {

    switch axis in mapping {
        case GamepadAxis: return #force_inline resolve_gamepad_axis(axis)
        case MouseAxis: return #force_inline resolve_mouse_axis(axis)
        case VirtualAxis: return #force_inline resolve_virtual_axis(axis)
    }

    return 0
}

@(private)
resolve_virtual_axis :: proc(
    mapping: VirtualAxis
) -> ResolvedAxis {
    positiveAction := resolve_action(mapping.positive)
    negativeAction := resolve_action(mapping.negative)

    finalVal : f32 = 0.0

    if positiveAction == .Down || positiveAction == .Pressed do finalVal += 1.0
    if negativeAction == .Down || negativeAction == .Pressed do finalVal -= 1.0

    return finalVal
}