package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

/*
Creates the player entity and returns their entity-handle-ids
*/
create_player :: proc(
    startPosition, startScale: rl.Vector2,
    baseSpeed, baseHealth, baseDamage: f32
) -> (playerID, gunID: ecs.entity_id) {
    playerEntity := create_entity(true)

    playerTransform, _ := ecs.add_component(&comps.t_Transform, playerEntity)
    playerTransform.position = startPosition
    playerTransform.scale = startScale
    playerTransform.origin = rl.Vector2{ 0.5, 0.5 }
    //playerTransform.rotation = 90

    playerVelocity, _ := ecs.add_component(&comps.t_Velocity, playerEntity)
    playerVelocity.deceleration_coeff = 0.98

    playerLookAt, _ := ecs.add_component(&comps.t_TransformLookAt, playerEntity)
    playerLookAt.target = comps.LookatMouse{}

    playerSpriteRenderer, _ := ecs.add_component(&comps.t_SpriteRenderer, playerEntity)
    playerSpriteRenderer.sprite = resource.PrimitvieRect{}
    playerSpriteRenderer.color = rl.GREEN

    ecs.add_component(&comps.t_Cullable, playerEntity)

    playerStats, _ := ecs.add_component(&comps.t_PlayerStats, playerEntity)
    playerStats.currentHealth = baseHealth
    playerStats.maxHealth = baseHealth
    playerStats.damage = baseDamage

    movementStats, _ := ecs.add_component(&comps.t_MovementStats, playerEntity)
    movementStats.speed = baseSpeed
    movementStats.acceleration = 2

    movementInput, _ := ecs.add_component(&comps.t_MovementInput, playerEntity)
    movementInput.forwardKey = rl.KeyboardKey.W
    movementInput.backwardKey = rl.KeyboardKey.S
    movementInput.leftKey = rl.KeyboardKey.A
    movementInput.rightKey = rl.KeyboardKey.D

    playerHashable, _ := ecs.add_component(&comps.t_HashableEntity, playerEntity)

    playerCollider, _ := ecs.add_component(&comps.t_Collider, playerEntity)
    playerCollider.offX = playerTransform.scale[0] / 2
    playerCollider.offY = playerTransform.scale[1] / 2

    playerCollisionChecker, _ := ecs.add_component(&comps.t_CollisionChecker, playerEntity)
    playerCollisionChecker.type = .BoxCastCollision

    gunEntity := create_gun(playerEntity, baseDamage)
    return playerEntity, gunEntity
}