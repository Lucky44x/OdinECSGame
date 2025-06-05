package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"

@(private="file")
v_object_selection: ecs.View
@(private="file")
it_object_selection: ecs.Iterator

@(private)
init_s_object_selection :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_object_selection, db, { &comp.t_SpriteRenderer, &comp.t_Transform })
    ecs.iterator_init(&it_object_selection, &v_object_selection)
}

/*
Gets the entity currently underneath the specified position
*/
s_object_selection :: proc(
    position: rl.Vector2
) -> (db: ^ecs.Database, eid: ecs.entity_id) {
    for ecs.iterator_next(&it_object_selection) {
        eid := ecs.get_entity(&it_object_selection)

        spriteRend: ^comp.c_SpriteRenderer = ecs.get_component(&comp.t_SpriteRenderer, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        checkRec := rl.Rectangle{
            transform.position[0] - (transform.origin[0] * transform.scale[0]),
            transform.position[1] - (transform.origin[1] * transform.scale[1]),
            transform.scale[0],
            transform.scale[1]
        }

        #partial switch type in spriteRend.sprite {
            case resource.PrimitiveEllipse:
                checkRec.x -= transform.scale[0]
                checkRec.y -= transform.scale[1]
                checkRec.width *= 2
                checkRec.height *= 2
                break
        }

        if rl.CheckCollisionPointRec(position, checkRec) {
            ecs.iterator_reset(&it_object_selection)
            return v_object_selection.db, eid
        }
    }

    fmt.printfln("None found");
    ecs.iterator_reset(&it_object_selection)
    return nil, {}
}

/*
Draws the debug aabb around objects
*/
s_draw_object_selection :: proc() {
    for ecs.iterator_next(&it_object_selection) {
        eid := ecs.get_entity(&it_object_selection)

        spriteRend: ^comp.c_SpriteRenderer = ecs.get_component(&comp.t_SpriteRenderer, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        checkRec := rl.Rectangle{
            transform.position[0] - (transform.origin[0] * transform.scale[0]),
            transform.position[1] - (transform.origin[1] * transform.scale[1]),
            transform.scale[0],
            transform.scale[1]
        }

        #partial switch type in spriteRend.sprite {
            case resource.PrimitiveEllipse:
                checkRec.x -= transform.scale[0]
                checkRec.y -= transform.scale[1]
                checkRec.width *= 2
                checkRec.height *= 2
                break
        }
        rl.DrawRectangleLinesEx(checkRec, 2, rl.DARKGREEN)
    }

    ecs.iterator_reset(&it_object_selection)
}