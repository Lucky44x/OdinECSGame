package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "../../profiling"

@(private="file")
v_spline_renderer_render: ecs.View
@(private="file")
it_spline_renderer_render: ecs.Iterator

@(private)
init_s_spline_renderer_render :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_spline_renderer_render, db, { &comp.t_SplineRenderer, &comp.t_Transform, &comp.t_Cullable })
    ecs.iterator_init(&it_spline_renderer_render, &v_spline_renderer_render)
}

/*
Renders all Spline Renderer Components
*/
s_spline_renderer_render :: proc() {
    profiling.profile_scope("SplineRenderer System")

    for ecs.iterator_next(&it_spline_renderer_render) {
        eid := ecs.get_entity(&it_spline_renderer_render)

        if !check_is_active(eid) do continue

        culled: ^comp.c_Cullable = ecs.get_component(&comp.t_Cullable, eid)
        if culled.culled do continue

        splineRend: ^comp.c_SplineRenderer = ecs.get_component(&comp.t_SplineRenderer, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        points: [4]rl.Vector2
        points[0] = transform.position + splineRend.startPoint
        points[1] = transform.position + splineRend.controlPointStart
        points[2] = transform.position + splineRend.controlPointEnd
        points[3] = transform.position + splineRend.endPoint

        rl.DrawSplineBezierCubic(&points[0], 4, splineRend.thickness, splineRend.color)
    }

    ecs.iterator_reset(&it_spline_renderer_render)
}