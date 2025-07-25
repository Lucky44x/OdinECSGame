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

import types "../../../../libs/datatypes"

@(private="file")
v_factory_build_conv: ecs.View
@(private="file")
it_factory_build_conv: ecs.Iterator

@(private)
init_s_factory_build_conv :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_build_conv, db, { &comp.t_State, &comp.t_ConveyorBuilder, &comp.t_Transform })
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

        snapPointFound, snapPos, snapDir, snapType, snapEID := partioning.get_snappoint(args.hashedPartition, rl.GetMousePosition())
        snapConnectible: bool = snapPointFound

        scrollWheelInput := args.inputMap.axes[input.Axes.ScrollVertical] * rl.GetFrameTime() * 250

        if !builder.isActive {

            transform.position = rl.GetMousePosition()
            transform.rotation -= scrollWheelInput
            
            if snapPointFound && snapType == .Output {
                transform.position = snapPos
                transform.rotation = 180 - snapDir
            } else do snapConnectible = false
            
            if transform.rotation >= 360 do transform.rotation = 0
            if transform.rotation < 0 do transform.rotation = 360

            if args.inputMap.actions[input.Actions.ConfirmPlacement] != .Pressed do continue

            builder.isActive = true

            intake := comp.add_intake(eid, 1)

            convRenderer, _ := ecs.add_component(&comp.t_SplineRenderer, eid)
            convRenderer.startPoint = rl.Vector2{ 0, 0 }
            convRenderer.endPoint = rl.Vector2{ 0, 0 }
            convRenderer.controlPointStart = rl.Vector2{ 0, 0 }
            convRenderer.controlPointEnd = rl.Vector2{ 0, 0 }

            convRenderer.startDir = transform.rotation - 180
            convRenderer.endDir = 0

            convRenderer.thickness = 25
            convRenderer.color = rl.DARKGRAY

            transform.scale = { 1, 1 }
            transform.origin = { 0, 0 }
            transform.rotation = 0

            //Set Connection in passthrough
            if snapConnectible {
                //fmt.printfln("Found connectible snappoint: %i with comps: %v, %f, %e", snapEID, snapPos, snapDir, snapType)

                logiPassthrough : ^comp.c_LogisticPassthrough = ecs.get_component(&comp.t_LogisticPassthrough, snapEID)
                assert(logiPassthrough != nil, "Snappoint does not have passthrough comp")

                if logiPassthrough.linkedInput != nil {
                    fmt.printfln("Somehow, passthrough already has link on intake...")
                    continue
                }

                logiPassthrough.linkedInput = intake
                logiPassthrough.linkedInputSlot = 0
                logiPassthrough.linkedInputTransform = transform

            } else {
                entities.create_snappoint(transform, intake, 0, nil, 0, transform, nil, .Input, { 0, 0 }, convRenderer.startDir)
            }

            continue
        }

        spline: ^comp.c_SplineRenderer = ecs.get_component(&comp.t_SplineRenderer, eid)

        spline.endDir -= scrollWheelInput

        spline.endPoint = rl.GetMousePosition() - transform.position
        
        if snapPointFound && snapType == .Input { 
            spline.endPoint = snapPos - transform.position
            spline.endDir = 180 - snapDir
        } else do snapConnectible = false
        
        if spline.endDir >= 360 do spline.endDir = 0
        if spline.endDir < 0 do spline.endDir = 360

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
            facConv, _ := ecs.add_component(&comp.t_FactoryConveyor, eid)
            types.queue_init(&facConv.itemQueue)

            output := comp.add_output(eid, 1)

            ecs.remove_component(&comp.t_ConveyorBuilder, eid)
            //ecs.remove_component(&comp.t_SpriteRenderer, eid)

            if snapConnectible {
                logiPassthrough : ^comp.c_LogisticPassthrough = ecs.get_component(&comp.t_LogisticPassthrough, snapEID)
                assert(logiPassthrough != nil, "Snappoint does not have passthrough comp")

                if logiPassthrough.linkedOutput != nil {
                    fmt.printfln("Somehow, passthrough already has link on output...")
                    continue
                }

                logiPassthrough.linkedOutput = output
                logiPassthrough.linkedOutputSlot = 0
                logiPassthrough.linkedOutputTransform = transform
            } else {
                entities.create_snappoint(transform, nil, 0, output, 0, nil, transform, .Output, spline.endPoint, spline.endDir)
            }
        }
    }

    ecs.iterator_reset(&it_factory_build_conv)
}