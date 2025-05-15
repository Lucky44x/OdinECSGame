package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Enemystats component and table
*/
c_EnemyStats :: struct {
    health: f32
}

t_EnemyStats: ecs.Table(c_EnemyStats)