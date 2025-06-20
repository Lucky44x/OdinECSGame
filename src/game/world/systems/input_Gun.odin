package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../input"
import "../../profiling"

@(private="file")
v_gun_input: ecs.View
@(private="file")
it_gun_input: ecs.Iterator

@(private)
init_s_gun_input :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_gun_input, db, { &comp.t_GunStats, &comp.t_Transform })
    ecs.iterator_init(&it_gun_input, &v_gun_input)
}

/*
Handle the Gun Input and Shooting behaviour
*/
s_gun_input :: proc(
    inputMap: ^input.ResolvedInputMap,
    camOffset: rl.Vector2,
    camShake: proc(f32, f32),
    spawnBullet: proc(f32, f32, f32, rl.Vector2, rl.Vector2, rl.Vector2)
) {
    profiling.profile_scope("GunInput System")

    for ecs.iterator_next(&it_gun_input) {
        eid := ecs.get_entity(&it_gun_input)

        if !check_is_active(eid) do continue

        stats: ^comp.c_GunStats = ecs.get_component(&comp.t_GunStats, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)

        if inputMap.actions[input.Actions.Shoot] != .Pressed do continue

        camShake(5, 0.25)

        dir := (rl.GetMousePosition() + camOffset) - transform.position

        spawnBullet(
            stats.bulletSpeed,
            stats.gunDamage,
            45,
            transform.position,
            {5, 5},
            dir
        )
    }

    ecs.iterator_reset(&it_gun_input)
}