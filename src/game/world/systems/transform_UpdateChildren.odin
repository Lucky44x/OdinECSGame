package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../profiling"

@(private="file")
v_children_transform_update: ecs.View
@(private="file")
it_children_transform_update: ecs.Iterator

@(private)
init_s_children_transform_update :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_children_transform_update, db, { &comp.t_TransformChild, &comp.t_Transform })
    ecs.iterator_init(&it_children_transform_update, &v_children_transform_update)
}

/*
Updates child-transforms to follow their parent's position, rotation and scale
*/
s_children_transform_update :: proc() {
    profiling.profile_scope("TransformChildren System")

    for ecs.iterator_next(&it_children_transform_update) {
        eid := ecs.get_entity(&it_children_transform_update)
       
        if !check_is_active(eid) do continue

        //spriteRend: ^c_SpriteRenderer = ecs.get_component(&t_SpriteRenderer, eid)
        childTransform: ^comp.c_TransformChild = ecs.get_component(&comp.t_TransformChild, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        //Dereference so we cannot modify the parent
        parentTransform: comp.c_Transform = childTransform.parent^

        //Rotate the offset around origin
        relative_offset := childTransform.offsetPosition * parentTransform.scale
        rotatedOffset := rl.Vector2Rotate(relative_offset, parentTransform.rotation * rl.DEG2RAD)

        //Apply transforms to base-transform
        transform.rotation = parentTransform.rotation + childTransform.offsetRotation
        transform.position = parentTransform.position + rotatedOffset
        transform.scale = parentTransform.scale * childTransform.offsetScale
    }

    ecs.iterator_reset(&it_children_transform_update)
}