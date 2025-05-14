package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../../../resource"

/*
    Animator Component (Currently no Table since we aren't actively using it)
*/

c_Animator :: struct {
    clip: ^resource.AnimationClip,
    currentTime, animationSpeed: f32,
    currentFrame: i32
}