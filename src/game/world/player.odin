package world

import "core:math/linalg"
import rl "vendor:raylib"
import "../../resource"
import ecs "../../../libs/ode_ecs"

//General Data
@(private="file")MOVEMENT_SCALAR :: 2

//Components
@(private="file")
c_PlayerStats :: struct {
    currentHealth, maxHealth, damage: f32
}

@(private="file")
c_MovementInput :: struct {
    forwardKey, backwardKey, leftKey, rightKey: rl.KeyboardKey
}

//Tables
@(private="file") t_PlayerStats: ecs.Table(c_PlayerStats)
@(private="file") t_MovementInput: ecs.Table(c_MovementInput)

//Views
@(private="file") v_PlayerMovement: ecs.View
@(private="file") it_PlayerMovement: ecs.Iterator

//Systems

/*
Handles movement Input and lerps the players velocity vector towards the desired movement vector
*/
s_movementInput :: proc() {
    for ecs.iterator_next(&it_PlayerMovement) {
        eid := ecs.get_entity(&it_PlayerMovement)

        state: ^c_State = ecs.get_component(&t_State, eid)
        if !state^ do continue

        velocity: ^c_Velocity = ecs.get_component(&t_Velocity, eid)
        input: ^c_MovementInput = ecs.get_component(&t_MovementInput, eid)
        stats: ^c_MovementStats = ecs.get_component(&t_MovementStats, eid)

        input_vec: rl.Vector2 = { 0,0 }

        if rl.IsKeyDown(input.forwardKey) {
            input_vec[1] = -1
        } else if rl.IsKeyDown(input.backwardKey) {
            input_vec[1] = 1
        }

        if rl.IsKeyDown(input.rightKey) {
            input_vec[0] = 1
        } else if rl.IsKeyDown(input.leftKey) {
            input_vec[0] = -1
        }

        input_vec_norm := rl.Vector2Normalize(input_vec)
        movement := input_vec_norm * stats.speed

        velocity.velocity = linalg.lerp(velocity.velocity, movement, rl.GetFrameTime() * stats.acceleration * MOVEMENT_SCALAR)
    }

    ecs.iterator_reset(&it_PlayerMovement)
}

//General functions
/*
Initializes the player-specific component Tables
*/
init_comp_player :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_PlayerStats, db, 5000)
    ecs.table_init(&t_MovementInput, db, 5000)

    ecs.view_init(&v_PlayerMovement, db, {&t_MovementStats, &t_MovementInput, &t_Velocity})
    ecs.iterator_init(&it_PlayerMovement, &v_PlayerMovement)
}

/*
Creates the player entity and returns their entity-handle-ids
*/
player_create :: proc(
    startPosition, startScale: rl.Vector2,
    baseSpeed, baseHealth, baseDamage: f32
) -> (playerID, gunID: ecs.entity_id) {
    playerEntity := entity_create(true)

    playerTransform, _ := ecs.add_component(&t_Transform, playerEntity)
    playerTransform.position = startPosition
    playerTransform.scale = startScale
    playerTransform.origin = rl.Vector2{ 0.5, 0.5 }
    //playerTransform.rotation = 90

    playerVelocity, _ := ecs.add_component(&t_Velocity, playerEntity)
    playerVelocity.deceleration_coeff = 0.98

    playerLookAt, _ := ecs.add_component(&t_TransformLookAt, playerEntity)
    playerLookAt.target = LookatMouse{}

    playerSpriteRenderer, _ := ecs.add_component(&t_SpriteRenderer, playerEntity)
    playerSpriteRenderer.sprite = resource.PrimitvieRect{}
    playerSpriteRenderer.color = rl.GREEN

    ecs.add_component(&t_Cullable, playerEntity)

    playerStats, _ := ecs.add_component(&t_PlayerStats, playerEntity)
    playerStats.currentHealth = baseHealth
    playerStats.maxHealth = baseHealth
    playerStats.damage = baseDamage

    movementStats, _ := ecs.add_component(&t_MovementStats, playerEntity)
    movementStats.speed = baseSpeed
    movementStats.acceleration = 2

    movementInput, _ := ecs.add_component(&t_MovementInput, playerEntity)
    movementInput.forwardKey = rl.KeyboardKey.W
    movementInput.backwardKey = rl.KeyboardKey.S
    movementInput.leftKey = rl.KeyboardKey.A
    movementInput.rightKey = rl.KeyboardKey.D

    //playerHashable, _ := ecs.add_component(&t_HashableEntity, playerEntity)
    //playerHashable.type = { .PLAYER }

    playerCollider, _ := ecs.add_component(&t_Collider, playerEntity)
    playerCollider.offX = playerTransform.scale[0] / 2
    playerCollider.offY = playerTransform.scale[1] / 2

    playerCollisionChecker, _ := ecs.add_component(&t_CollisionChecker, playerEntity)
    playerCollisionChecker.type = .BoxCastCollision

    gunEntity := gun_create(playerEntity, baseDamage)
    return playerEntity, gunEntity
}