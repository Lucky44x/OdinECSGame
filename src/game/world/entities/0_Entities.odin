package entities

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

import comp "../components"

@(private="file")
db: ^ecs.Database

player_transform_ref: ^comp.c_Transform

init_entities :: proc(
    database: ^ecs.Database
) {
    db = database

    init_bullet()
    init_enemy()
}

create_entity :: proc(
    default_state: bool = false
) -> ecs.entity_id {
    eid, _ := ecs.create_entity(db)
    state, _ := ecs.add_component(&comp.t_State, eid)
    state ^= default_state

    return eid
}

destroy_entity :: proc(
    eid: ecs.entity_id
) {
    ecs.destroy_entity(db, eid)
}