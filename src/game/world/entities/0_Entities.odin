package entities

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

import comp "../components"

@(private="file")
db: ^ecs.Database

init_entities :: proc(
    database: ^ecs.Database
) {
    db = database

    init_bullet()
}

create_entity :: proc(
    default_state: bool = false
) -> ecs.entity_id {
    eid, _ := ecs.create_entity(db)
    state, _ := ecs.add_component(&comp.t_State, eid)
    state ^= default_state

    return eid
}