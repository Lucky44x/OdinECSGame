package systems

import ecs "../../../../libs/ode_ecs"
import comp "../components"

init_systems :: proc(
    db: ^ecs.Database
) {
    init_s_apply_velocity(db)
    init_s_boids_apply_movement(db)
    init_s_boids_update(db)
    init_s_children_transform_update(db)
    init_s_cull_entities(db)
    init_s_gun_input(db)
    init_s_movement_input(db)
    init_s_sprite_renderer_render(db)
    init_s_transform_lookat_target(db)
    init_s_build_hash_partition(db)
    init_s_debug_inspectables(db)
    init_s_spline_renderer_render(db)
    init_s_factory_build_conv(db)
    init_s_debug_draw_snappoints(db)
    init_s_factory_passthrough_update(db)
    init_s_factory_slot_cleanup_update(db)
    init_s_factory_render_conv_items(db)
    init_s_factory_conv_update(db)
    init_s_factory_machine_update(db)
    init_s_factory_recipe_setter(db)
}

@(private)
check_is_active :: proc(
    eid: ecs.entity_id
) -> bool {
    return ecs.get_component(&comp.t_State, eid)^
}