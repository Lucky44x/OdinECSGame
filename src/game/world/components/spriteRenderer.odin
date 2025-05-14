package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../../../resource"

/*
    Spriterenderer Component and Table
*/
c_SpriteRenderer :: struct {
    flipX, flipY: bool,
    sprite: resource.Renderable,
    color: rl.Color
}