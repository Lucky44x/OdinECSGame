package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../partioning"
import "../../profiling"

@(private="file")
v_build_hash_partition: ecs.View
@(private="file")
it_build_hash_partition: ecs.Iterator

@(private)
init_s_build_hash_partition :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_build_hash_partition, db, { &comp.t_Transform, &comp.t_HashableEntity })
    ecs.iterator_init(&it_build_hash_partition, &v_build_hash_partition)
}

s_build_hash_partion :: proc(
    self: ^partioning.HashedPartionMap
) {
    profiling.profile_scope("BuildHashpartition System")

    for ecs.iterator_next(&it_build_hash_partition) {
        eid := ecs.get_entity(&it_build_hash_partition)

        if !check_is_active(eid) do continue

        culled: ^comp.c_Cullable = ecs.get_component(&comp.t_Cullable, eid)
        if culled.culled do continue

        partioning.insert_entity(self, eid)
    }

    ecs.iterator_reset(&it_build_hash_partition)
}