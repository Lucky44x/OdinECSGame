package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    General Datatypes
*/
CollisionType :: enum {
    KinematicCollision,
    BoxCastCollision
}

/*
    CollisionChecker component and Table
*/
c_CollisionChecker :: struct{
    type: CollisionType
}

t_CollisionChecker: ecs.Table(c_CollisionChecker)