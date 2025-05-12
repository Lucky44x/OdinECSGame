package world

import rl "vendor:raylib"
import "../../resource"

// Component DEFS

c_Animator :: struct {
    clip: ^resource.AnimationClip,
    currentTime, animationSpeed: f32,
    currentFrame: i32
}