package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "core:math/linalg"
import "../../profiling"
import "../../../input"
import "../partioning"
import "../entities"

@(private="file")
v_factory_build_conv: ecs.View
@(private="file")
it_factory_build_conv: ecs.Iterator

@(private)
init_s_factory_build_conv :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_build_conv, db, { &comp.t_ConveyorBuilder, &comp.t_SplineRenderer, &comp.t_Transform })
    ecs.iterator_init(&it_factory_build_conv, &v_factory_build_conv)
}

FactoryBuildArgs :: struct {
    inputMap: ^input.ResolvedInputMap,
    hashedPartition: ^partioning.HashedPartionMap
}

/*
Updates the conveyor builders to build a conveyor
*/
s_factory_build_conv :: proc(args: ^FactoryBuildArgs) {
    profiling.profile_scope("ConvBuild System")

    for ecs.iterator_next(&it_factory_build_conv) {
        eid := ecs.get_entity(&it_factory_build_conv)

        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        builder: ^comp.c_ConveyorBuilder = ecs.get_component(&comp.t_ConveyorBuilder, eid)
        spline: ^comp.c_SplineRenderer = ecs.get_component(&comp.t_SplineRenderer, eid)

        spline.endDir -= rl.GetMouseWheelMoveV()[1] * rl.GetFrameTime() * 250
        if spline.endDir >= 360 do spline.endDir = 0
        if spline.endDir < 0 do spline.endDir = 360

        snapPointFound, snapPos, snapDir := partioning.get_snappoint(args.hashedPartition, rl.GetMousePosition())

        spline.endPoint = rl.GetMousePosition() - transform.position
        if snapPointFound { 
            spline.endPoint = snapPos - transform.position
            spline.endDir = snapDir
        }

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

        if args.inputMap.actions[input.Actions.ConfirmPlacement] == .Pressed {
            ecs.add_component(&comp.t_FactoryConveyor, eid)
            ecs.remove_component(&comp.t_ConveyorBuilder, eid)

            if !snapPointFound {
                //Check if we connected to a snap-point... if not we have a free-standing connection meaning we will need to create a new snappoint
                oppositeDirF := spline.endDir + 180
                if oppositeDirF < 0 do oppositeDirF += 360
                oppositeDirI := i32(oppositeDirF) % 360
                entities.create_snappoint(transform, spline.endPoint, f32(oppositeDirI))
                fmt.printfln("StartPos: %v, EndPos: %v", spline.startPoint, spline.endPoint)
                fmt.printfln("Creating snappoint at local: %v -- global: %v", spline.endPoint, spline.endPoint + transform.position)
            }
        }
    }

    ecs.iterator_reset(&it_factory_build_conv)
}