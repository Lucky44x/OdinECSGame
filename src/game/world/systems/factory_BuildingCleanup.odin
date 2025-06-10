package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "core:fmt"
import "core:math/linalg"
import "../../profiling"
import "../../../input"

@(private="file")
v_factory_build_cleanup_conv: ecs.View
@(private="file")
it_factory_build_cleanup_conv: ecs.Iterator

@(private)
init_s_factory_build_cleanup_conv :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_factory_build_cleanup_conv, db, { &comp.t_ConveyorBuilder, &comp.t_FactoryConveyor })
    ecs.iterator_init(&it_factory_build_cleanup_conv, &v_factory_build_cleanup_conv)
}

/*
Cleans the builder component from conveyors
*/
s_factory_build_cleanup_conv :: proc(inputMap: ^input.ResolvedInputMap) {
    profiling.profile_scope("ConvBuild System")

    for ecs.iterator_next(&it_factory_build_cleanup_conv) {
        eid := ecs.get_entity(&it_factory_build_cleanup_conv)

        ecs.remove_component(&comp.t_ConveyorBuilder, eid)
    }

    ecs.iterator_reset(&it_factory_build_cleanup_conv)
}