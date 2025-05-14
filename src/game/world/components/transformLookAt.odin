package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    General Datatypes
*/
LookatMouse :: struct{}
LookatTransform :: ^c_Transform

LookatTarget :: union {
    LookatMouse,
    LookatTransform
}

/*
    Transform Lookat Component and Table
*/
c_TransformLookAt :: struct {
    target: LookatTarget
}

t_TransformLookAt: ecs.Table(c_TransformLookAt)