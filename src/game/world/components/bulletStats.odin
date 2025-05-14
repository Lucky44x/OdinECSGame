package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Bullet-Stats Component and Table
*/

c_BulletStats :: struct {
    speed, damage, lifetime, max_lifetime: f32
}

t_BulletStats: ecs.Table(c_BulletStats)