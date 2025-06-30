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
v_factory_render_conv_items: ecs.View
@(private="file")
it_factory_render_conv_items: ecs.Iterator

@(private)
init_s_factory_render_conv_items :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_render_conv_items, db, { &comp.t_State, &comp.t_Transform, &comp.t_SplineRenderer, &comp.t_FactoryConveyor })
    ecs.iterator_init(&it_factory_render_conv_items, &v_factory_render_conv_items)
}

/*
Renders the items on the conveyor
*/
s_factory_render_conv_items :: proc(args: ^FactoryBuildArgs) {
    profiling.profile_scope("ConvRender-Items System")

    for ecs.iterator_next(&it_factory_render_conv_items) {
        eid := ecs.get_entity(&it_factory_render_conv_items)
        if !check_is_active(eid) do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        spline: ^comp.c_SplineRenderer = ecs.get_component(&comp.t_SplineRenderer, eid)
        conv: ^comp.c_FactoryConveyor = ecs.get_component(&comp.t_FactoryConveyor, eid)

        idx := conv.itemQueue.read
        for i : u32 = 0; i < conv.itemQueue.count; i += 1 {
            if idx >= conv.itemQueue.write do break //Better safe than sorry

            item : ^comp.ConveyorItem = &conv.itemQueue.ring[idx]
            if item == nil do continue

            renderPos := transform.position + rl.GetSplinePointBezierCubic(
                spline.startPoint, spline.controlPointStart,
                spline.controlPointEnd, spline.endPoint,
                item.distance / 10
            )

            itemDescriptor := resource.GetItemByID(item.item)

            resource.render_sprite(&itemDescriptor.sprite, renderPos, 0)

            //rl.DrawCircleV(renderPos, 15, rl.RED)

            idx += 1
        }
    }

    ecs.iterator_reset(&it_factory_render_conv_items)
}

bezier_point :: proc()