package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"

v_apply_velocity: ecs.View
it_apply_velocity: ecs.Iterator

/*
Moves every Transform by its Velocity Vector
*/
s_apply_velocity :: proc() {
    for ecs.iterator_next(&it_apply_velocity) {
        eid := ecs.get_entity(&it_apply_velocity)

        if !check_is_active(eid) do continue

        vel: ^comp.c_Velocity = ecs.get_component(&comp.t_Velocity, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        transform.position += vel.velocity
        vel.velocity *= vel.deceleration_coeff
    }

    ecs.iterator_reset(&it_apply_velocity)
}