package world

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"
import "core:fmt"

//General Data
CollisionType :: enum {
    KinematicCollision,
    BoxCastCollision
}

//Components
c_Collider :: struct{
    offX, offY, offW, offH: f32,
    rect: rl.Rectangle
}

c_CollisionChecker :: struct{
    type: CollisionType
}

//Table
t_Collider: ecs.Table(c_Collider)
t_CollisionChecker: ecs.Table(c_CollisionChecker)

//Views
v_ColliderUpdate: ecs.View
it_ColliderUpdate: ecs.Iterator

v_CollisionCheck: ecs.View
it_CollisionCheck: ecs.Iterator

//Systems
s_collider_update :: proc() {
    for ecs.iterator_next(&it_ColliderUpdate) {
        eid := ecs.get_entity(&it_ColliderUpdate)

        state: ^c_State = ecs.get_component(&t_State, eid)
        if !state^ do continue

        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)
        collider: ^c_Collider = ecs.get_component(&t_Collider, eid)
    
        collider.rect.x = transform.position[0] - collider.offX
        collider.rect.y = transform.position[1] - collider.offY
        collider.rect.width = transform.scale[0] - collider.offW
        collider.rect.height = transform.scale[1] - collider.offH
    }

    ecs.iterator_reset(&it_ColliderUpdate)
}

debug_draw_colliders :: proc() {
    for ecs.iterator_next(&it_ColliderUpdate) {
        eid := ecs.get_entity(&it_ColliderUpdate)

        state: ^c_State = ecs.get_component(&t_State, eid)
        if !state^ do continue

        collider: ^c_Collider = ecs.get_component(&t_Collider, eid)
        rl.DrawRectanglePro(collider.rect, {0,0}, 0, rl.Color{ 127, 106, 79, 125 })
    }

    ecs.iterator_reset(&it_ColliderUpdate)
}

s_collision_checker :: proc() {
    for ecs.iterator_next(&it_CollisionCheck) {
        eid := ecs.get_entity(&it_CollisionCheck)

        state: ^c_State = ecs.get_component(&t_State, eid)
        if !state^ do continue

        collider: ^c_Collider = ecs.get_component(&t_Collider, eid)
        collisionchecker: ^c_CollisionChecker = ecs.get_component(&t_CollisionChecker, eid)

        otherCol: ^c_Collider
        otherId: ecs.entity_id

        //Handle the two ways of collision (should normally be seperated into seperate Components and Systems, but eeh)
        if collisionchecker.type == .KinematicCollision {
            otherCol, otherId = check_rec_collision_with_entitties(eid, collider.rect)
        } else {
            vel: ^c_Velocity = ecs.get_component(&t_Velocity, eid)
            trans: ^c_Transform = ecs.get_component(&t_Transform, eid)

            originalPos := trans.position - vel.velocity

            otherCol, otherId = get_collision_with_entity_cast(originalPos, trans.position, collider, eid)
        }

        if otherCol == nil do continue

        //fmt.printfln("Collided with something: %i: %s", eid, otherCol)
        spawn_collision_event(eid, otherId)
    }

    ecs.iterator_reset(&it_CollisionCheck)
}

//General Functions
init_comp_collision :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_Collider, db, 5000)
    ecs.table_init(&t_CollisionChecker, db, 5000)

    ecs.view_init(&v_ColliderUpdate, db, {&t_Transform, &t_Collider})
    ecs.iterator_init(&it_ColliderUpdate, &v_ColliderUpdate)

    ecs.view_init(&v_CollisionCheck, db, {&t_Collider, &t_CollisionChecker})
    ecs.iterator_init(&it_CollisionCheck, &v_CollisionCheck)
}