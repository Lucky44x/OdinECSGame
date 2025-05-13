package world

import rl "vendor:raylib"
import ecs "../../../libs/ode_ecs"

import "core:fmt"

//General Data
eventPool: Pool

//Components
c_CollisionEvent :: struct {
    entityA, entityB: ecs.entity_id,
    entityATags, entityBTags: bit_set[EntityType]
}

//Tables
t_CollisionEvent: ecs.Table(c_CollisionEvent)

//Views
v_CollisionEvent: ecs.View
it_CollisionEvent: ecs.Iterator

//Systems
s_resolve_collisions :: proc() {
    for ecs.iterator_next(&it_CollisionEvent) {
        eid := ecs.get_entity(&it_CollisionEvent)
    
        isInactive := ecs.has_component(&t_Inactive, eid)
        if isInactive do continue

        event: ^c_CollisionEvent = ecs.get_component(&t_CollisionEvent, eid)
        if event.entityA.ix == 0 || event.entityB.ix == 0 do continue
            
        fmt.printfln("Resolved collision: %i -=- %i, pool count: %i, active: %b", event.entityA, event.entityB, eventPool.count, isInactive)
        pool_push(&eventPool, eid)
    }

    ecs.iterator_reset(&it_CollisionEvent)
}

spawn_collision_event :: proc(
    ownId, otherId: ecs.entity_id
) {
    eid := pool_pop(&eventPool)

    event: ^c_CollisionEvent = ecs.get_component(&t_CollisionEvent, eid)
    event.entityA = ownId
    event.entityB = otherId
}

build_collision_event :: proc() -> ecs.entity_id {
    eventEntity := entity_create()

    ecs.add_component(&t_Inactive, eventEntity)
    ecs.add_component(&t_CollisionEvent, eventEntity)
    return eventEntity
}

init_comp_collision_resolution :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_CollisionEvent, db, 5000)

    pool_init(&eventPool, db, build_collision_event, 15, 1024)

    ecs.view_init(&v_CollisionEvent, db, {&t_CollisionEvent})
    ecs.iterator_init(&it_CollisionEvent, &v_CollisionEvent)
}