package game

import rl "vendor:raylib"
import "../input"

InputMap_World: input.InputMap

init_input_mappings :: proc() {
    InputMap_World.actions[input.Actions.Shoot] = rl.MouseButton.LEFT
    InputMap_World.actions[input.Actions.ConfirmPlacement] = rl.MouseButton.LEFT
    InputMap_World.actions[input.Actions.DebugContextMenu] = rl.MouseButton.RIGHT

    InputMap_World.axes[input.Axes.MovementHorizontal] = input.VirtualAxis{
        rl.KeyboardKey.D,
        rl.KeyboardKey.A
    }

    //Movement Axis has to be inverted here
    InputMap_World.axes[input.Axes.MovementVertical] = input.VirtualAxis{
        rl.KeyboardKey.S,
        rl.KeyboardKey.W
    }
}