package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"

/*
    The Boid-Entity Component
*/

c_BoidParticle :: struct {
    player_transform: ^c_Transform,
    steering_vector: rl.Vector2,
    //player_weight, alignment_weight, cohesion_weight, seperation_weight, perception_radius, player_perception_radius: f32
}

t_BoidParticle: ecs.Table(c_BoidParticle)