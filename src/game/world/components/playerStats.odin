package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    Playerstats Component and Table
*/
c_PlayerStats :: struct {
    currentHealth : f32,
    maxHealth : f32, 
    damage: f32
}

t_PlayerStats: ecs.Table(c_PlayerStats)