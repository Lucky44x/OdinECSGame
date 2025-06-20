package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../profiling"

@(private="file")
v_cull_entities: ecs.View
@(private="file")
it_cull_entities: ecs.Iterator

@(private)
init_s_cull_entities:: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_cull_entities, db, { &comp.t_Cullable, &comp.t_Transform })
    ecs.iterator_init(&it_cull_entities, &v_cull_entities)
}

/*
Sets the respective entities to be culled, when outside the provided view-frustum
*/
s_cull_entities :: proc(
    frustum: rl.Rectangle
) {
    profiling.profile_scope("EntityCulling System")

    for ecs.iterator_next(&it_cull_entities) {
        eid := ecs.get_entity(&it_cull_entities)

        cullingData: ^comp.c_Cullable = ecs.get_component(&comp.t_Cullable, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        targetRect := rl.Rectangle{
            x = transform.position[0],
            y = transform.position[1],
            width = transform.scale[0],
            height = transform.scale[1]
        }

        if rl.CheckCollisionRecs(frustum, targetRect) do cullingData.culled = false
        else do cullingData.culled = true
    }

    ecs.iterator_reset(&it_cull_entities)
}