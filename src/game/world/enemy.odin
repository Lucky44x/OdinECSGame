package world

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../../resource"
import "core:math/linalg"
import "core:math/rand"

import "core:fmt"

@(private="file") MOVEMENT_SCALAR_ENEMY :: 2

/*
@(private="file") PERCEPTION_RADIUS_MAX : f32 : 1024
@(private="file") PERCEPTION_RADIUS_MIN : f32 : 256

@(private="file") PLAYER_PERCEPTION_RADIUS_MAX : f32 : 1024
@(private="file") PLAYER_PERCEPTION_RADIUS_MIN : f32 : 1024

@(private="file") PLAYER_WEIGHT_MAX : f32 : 0.25
@(private="file") PLAYER_WEIGHT_MIN : f32 : 0.15

@(private="file") ALIGNMENT_WEIGHT_MAX : f32 : 1
@(private="file") ALIGNMENT_WEIGHT_MIN : f32 : 3

@(private="file") SEPERATION_WEIGHT_MAX : f32 : 10
@(private="file") COHESION_WEIGHT_MAX : f32 : 3
*/

//Components
@(private="file")
c_EnemyStats :: struct {
    health: f32
}

//Tables
@(private="file") t_EnemyStats: ecs.Table(c_EnemyStats)

//Views
@(private="file") v_EnemyMovement: ecs.View
@(private="file") it_EnemyMovement: ecs.Iterator

//Systems
s_do_enemy_boid_movement :: proc() {
    for ecs.iterator_next(&it_EnemyMovement) {
        eid := ecs.get_entity(&it_EnemyMovement)

        movementStats: ^c_MovementStats = ecs.get_component(&t_MovementStats, eid)
        boidParticle: ^c_BoidParticle = ecs.get_component(&t_BoidParticle, eid)
        velocity: ^c_Velocity = ecs.get_component(&t_Velocity, eid)

        movement := rl.Vector2ClampValue(boidParticle.steering_vector, -movementStats.speed, movementStats.speed) //* movementStats.speed

        //fmt.printfln("%v", boidParticle.steering_vector)

        velocity.velocity = linalg.lerp(velocity.velocity, movement, rl.GetFrameTime() * movementStats.acceleration * MOVEMENT_SCALAR_ENEMY)
    }

    ecs.iterator_reset(&it_EnemyMovement)
}

//General Functions
init_comp_enemy :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_EnemyStats, db, 5000)

    ecs.view_init(&v_EnemyMovement, db, {&t_EnemyStats, &t_MovementStats, &t_BoidParticle, &t_Velocity})
    ecs.iterator_init(&it_EnemyMovement, &v_EnemyMovement)
}

/*
Creates an enemy of the specified size and position
*/
enemy_create :: proc(
    startPosition, startScale: rl.Vector2,
    baseSpeed: f32,
    playerRef: ^c_Transform
) -> ecs.entity_id {
    enemyEntity := entity_create()

    enemyTransform, _ := ecs.add_component(&t_Transform, enemyEntity)
    enemyTransform.position = startPosition
    enemyTransform.scale = startScale
    enemyTransform.origin = rl.Vector2{ 0.5, 0.5 }

    enemyVelocity, _ := ecs.add_component(&t_Velocity, enemyEntity)
    enemyVelocity.deceleration_coeff = 0

    playerLookAt, _ := ecs.add_component(&t_TransformLookAt, enemyEntity)
    playerLookAt.target = playerRef

    enemySpriteRenderer, _ := ecs.add_component(&t_SpriteRenderer, enemyEntity)
    enemySpriteRenderer.sprite = resource.PrimitvieRect{}
    enemySpriteRenderer.color = rl.RED

    ecs.add_component(&t_Cullable, enemyEntity)

    movementStats, _ := ecs.add_component(&t_MovementStats, enemyEntity)
    movementStats.speed = baseSpeed
    movementStats.acceleration = 2

    enemyHashable, _ := ecs.add_component(&t_HashableEntity, enemyEntity)
    enemyHashable.type = { .ENEMY, .BOID, .COLLIDES }

    enemyStats, _ := ecs.add_component(&t_EnemyStats, enemyEntity) 

    enemyBoid, _ := ecs.add_component(&t_BoidParticle, enemyEntity)
    enemyBoid.player_transform = playerRef
    /*
    enemyBoid.player_weight = PLAYER_WEIGHT_MAX
    enemyBoid.alignment_weight = ALIGNMENT_WEIGHT_MAX

    enemyBoid.cohesion_weight = COHESION_WEIGHT_MAX
    enemyBoid.seperation_weight = SEPERATION_WEIGHT_MAX

    enemyBoid.perception_radius = PERCEPTION_RADIUS_MAX
    enemyBoid.player_perception_radius = PLAYER_PERCEPTION_RADIUS_MAX
    */

    enemyCollider, _ := ecs.add_component(&t_Collider, enemyEntity)
    enemyCollider.offX = (enemyTransform.scale[0] / 2)
    enemyCollider.offY = (enemyTransform.scale[1] / 2)

    return enemyEntity
}
