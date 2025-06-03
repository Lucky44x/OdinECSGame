package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"

import "core:math/linalg"

@(private="file")
v_transform_lookat_target: ecs.View
@(private="file")
it_transform_lookat_target: ecs.Iterator

@(private)
init_s_transform_lookat_target :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_transform_lookat_target, db, { &comp.t_Transform, &comp.t_TransformLookAt })
    ecs.iterator_init(&it_transform_lookat_target, &v_transform_lookat_target)
}

/*
Rotates a Transform to look at a specific target
*/
s_transform_lookat_target :: proc(
    camOffset: rl.Vector2
) {
    targetPos: rl.Vector2 = rl.GetMousePosition()
    forward: rl.Vector2 = { 0, 1 }

    for ecs.iterator_next(&it_transform_lookat_target) {
        eid := ecs.get_entity(&it_transform_lookat_target)

        if !check_is_active(eid) do continue    //This had to be the dumbest error ever

        culled := ecs.get_component(&comp.t_Cullable, eid)
        if culled.culled do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        transformLookAt: ^comp.c_TransformLookAt = ecs.get_component(&comp.t_TransformLookAt, eid)
        myPos: rl.Vector2 = transform.position

        switch type in transformLookAt.target {
            case comp.LookatMouse:
                targetPos = rl.GetMousePosition() + camOffset
                break
            case ^comp.c_Transform:
                targetPos = type.position
                break
        }

        lookDir := targetPos - myPos
        angle := linalg.atan2(lookDir[1], lookDir[0]) - linalg.atan2(forward[1], forward[0])

        //Do Transformations
        transform.rotation = angle * rl.RAD2DEG

        //rl.DrawLine(i32(targetPos[0]), i32(targetPos[1]), i32(myPos[0]), i32(myPos[1]), rl.RED)
    }

    ecs.iterator_reset(&it_transform_lookat_target)
}