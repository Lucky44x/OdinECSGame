package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Transform-Child Component and Table
*/
c_TransformChild :: struct {
    offsetPosition, offsetScale: rl.Vector2,
    offsetRotation: f32,
    parent: ^c_Transform
}

t_TransformChild: ecs.Table(c_TransformChild)