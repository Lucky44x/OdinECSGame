package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "core:math/linalg"

@(private="file")
v_factory_build_conv: ecs.View
@(private="file")
it_factory_build_conv: ecs.Iterator

@(private)
init_s_factory_build_conv :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_build_conv, db, { &comp.t_FactoryConveyor, &comp.t_ConveyorBuilder, &comp.t_SplineRenderer, &comp.t_Transform })
    ecs.iterator_init(&it_factory_build_conv, &v_factory_build_conv)
}

//TODO: SWITCH TO QUADRATIC HERMITE CURVE FOR MORE CONTROL OVER DIRECTIONAL BASED START AND ENDPOINTS

//TODO: SIWTCH FROM SINGULAR CURVE RENDERER TO TWO CURVES RENDERED ON EACH SIDE OF THE BELT - Sractch that, just bump up the thickness

/*
Updates the conveyor builders to build a conveyor
*/
s_factory_build_conv :: proc() {
    for ecs.iterator_next(&it_factory_build_conv) {
        eid := ecs.get_entity(&it_factory_build_conv)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        builder: ^comp.c_ConveyorBuilder = ecs.get_component(&comp.t_ConveyorBuilder, eid)
        conveyor: ^comp.c_FactoryConveyor = ecs.get_component(&comp.t_FactoryConveyor, eid)
        spline: ^comp.c_SplineRenderer = ecs.get_component(&comp.t_SplineRenderer, eid)

        spline.endDir -= rl.GetMouseWheelMoveV()[1] * rl.GetFrameTime() * 250
        if spline.endDir >= 360 do spline.endDir = 0
        if spline.endDir < 0 do spline.endDir = 360

        spline.endPoint = rl.GetMousePosition() - transform.position
        
        deltaVector := spline.endPoint - spline.startPoint
        distance := rl.Vector2Length(deltaVector)
        base_handle_length := distance * 0.25

        angle_diff := abs(spline.endDir - spline.startDir)

        startDirVector := rl.Vector2{ linalg.sin(rl.DEG2RAD * spline.startDir), linalg.cos(rl.DEG2RAD * spline.startDir) }
        endDirVector := rl.Vector2{ linalg.sin(rl.DEG2RAD * spline.endDir), linalg.cos(rl.DEG2RAD * spline.endDir) }

        dot := rl.Vector2DotProduct(startDirVector, endDirVector)
        curvature_factor := 1.0 - dot
        curvature_factor = clamp(curvature_factor, 0.0, 1.5)

        handle_length := base_handle_length * (1 + curvature_factor)

        spline.controlPointStart = spline.startPoint + (startDirVector * handle_length)
        spline.controlPointEnd = spline.endPoint - (endDirVector * handle_length)
    }

    ecs.iterator_reset(&it_factory_build_conv)
}