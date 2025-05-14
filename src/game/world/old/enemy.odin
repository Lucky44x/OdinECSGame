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

//Pooling
@(private="file")
EnemiesPool: Pool

//Components
@(private="file")


//Tables
@(private="file") t_EnemyStats: ecs.Table(c_EnemyStats)

//Views
@(private="file") v_EnemyMovement: ecs.View
@(private="file") it_EnemyMovement: ecs.Iterator

//General Functions
init_comp_enemy :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_EnemyStats, db, 5000)

    pool_init(&EnemiesPool, db, enemy_build, 25, 1024)

    ecs.view_init(&v_EnemyMovement, db, {&t_EnemyStats, &t_MovementStats, &t_BoidParticle, &t_Velocity})
    ecs.iterator_init(&it_EnemyMovement, &v_EnemyMovement)
}

/*
Spawns an enemy with the given attributes
*/
enemy_spawn :: proc(
    startPosition, startScale: rl.Vector2,
    baseSpeed: f32,
    playerRef: ^c_Transform
) {
    enemy_entity := pool_pop(&EnemiesPool)

    fmt.printfln("Spawned entity: %i", enemy_entity)

    enemyTransform: ^c_Transform = ecs.get_component(&t_Transform, enemy_entity)
    enemyTransform.position = startPosition
    enemyTransform.scale = startScale
    enemyTransform.origin = rl.Vector2{ 0.5, 0.5 }

    enemyVelocity: ^c_Velocity = ecs.get_component(&t_Velocity, enemy_entity)
    enemyVelocity.deceleration_coeff = 0

    playerLookAt: ^c_TransformLookAt = ecs.get_component(&t_TransformLookAt, enemy_entity)
    playerLookAt.target = playerRef

    enemySpriteRenderer: ^c_SpriteRenderer = ecs.get_component(&t_SpriteRenderer, enemy_entity)
    enemySpriteRenderer.sprite = resource.PrimitvieRect{}
    enemySpriteRenderer.color = rl.RED

    movementStats: ^c_MovementStats = ecs.get_component(&t_MovementStats, enemy_entity)
    movementStats.speed = baseSpeed
    movementStats.acceleration = 2

    enemyHashable: ^c_HashableEntity = ecs.get_component(&t_HashableEntity, enemy_entity)
    enemyHashable.type = { .ENEMY, .BOID, .COLLIDES }

    enemyBoid: ^c_BoidParticle = ecs.get_component(&t_BoidParticle, enemy_entity)
    enemyBoid.player_transform = playerRef

    enemyCollider: ^c_Collider = ecs.get_component(&t_Collider, enemy_entity)
    enemyCollider.offX = (enemyTransform.scale[0] / 2)
    enemyCollider.offY = (enemyTransform.scale[1] / 2)

    ecs.rebuild(&v_EnemyMovement)
}

/*
Creates an enemy of the specified size and position
*/
enemy_build :: proc() -> ecs.entity_id {
    enemyEntity := entity_create()

    transform, _ := ecs.add_component(&t_Transform, enemyEntity)
    lookat, _ := ecs.add_component(&t_TransformLookAt, enemyEntity)
    velocity, _ := ecs.add_component(&t_Velocity, enemyEntity)
    spriteRend, _ := ecs.add_component(&t_SpriteRenderer, enemyEntity)
    cullable, _ := ecs.add_component(&t_Cullable, enemyEntity)
    movementStats, _ := ecs.add_component(&t_MovementStats, enemyEntity)
    hashData, _ := ecs.add_component(&t_HashableEntity, enemyEntity)
    stats, _ := ecs.add_component(&t_EnemyStats, enemyEntity) 
    boid, _ := ecs.add_component(&t_BoidParticle, enemyEntity)
    collider, _ := ecs.add_component(&t_Collider, enemyEntity)

    fmt.printfln("Built enemy: %i", enemyEntity)

    return enemyEntity
}
