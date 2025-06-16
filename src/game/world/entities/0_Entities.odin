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
    init_conveyor()
    init_snappoint()
    init_building()
}

deinit_entities :: proc() {
    deinit_enemy()
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

vec3ToVec2 :: proc(
    vec3: rl.Vector3,
    xInd, yInd: u8
) -> rl.Vector2 {
    return rl.Vector2{ vec3[xInd], vec3[yInd] }
}