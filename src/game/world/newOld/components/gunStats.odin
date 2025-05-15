package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Gunstats Component and Table
*/
c_GunStats :: struct {
    durabillity, rpm, spread, bulletSpeed, gunDamage: f32
}

t_GunStats: ecs.Table(c_GunStats)