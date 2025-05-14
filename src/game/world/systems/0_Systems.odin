package systems

import ecs "../../../../libs/ode_ecs"
import comp "../components"

init_systems :: proc(
    db: ^ecs.Database
) {

}

@(private)
check_is_active :: proc(
    eid: ecs.entity_id
) -> bool {
    return ecs.get_component(&comp.t_State, eid)^
}