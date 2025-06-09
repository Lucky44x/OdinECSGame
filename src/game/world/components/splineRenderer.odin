package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../../../resource"

//TODO: Implement

/**
Spline Renderer for Conveyor belts
*/
c_SplineRenderer :: struct {
    startPoint, endPoint, controlPointStart, controlPointEnd: rl.Vector2,
    startDir, endDir: f32,
    color: rl.Color,
    thickness: f32
}

t_SplineRenderer: ecs.Table(c_SplineRenderer)