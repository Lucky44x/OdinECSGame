package world

import "core:math/linalg"
import rl "vendor:raylib"
import "../../resource"
import ecs "../../../libs/ode_ecs"

//Components


//Views

//Systems

// General Functions
/*
Initializes the Bullet-specific components and their respective Tables
*/
init_comp_bullet :: proc(db: ^ecs.Database) {
    ecs.table_init(&t_BulletStats, db, 5000)
}

/*
Creates a Bullet and returns it's entityid
*/
bullet_create :: proc(
    startSpeed, damage, lifetime: f32,
    position, scale, direction: rl.Vector2
) -> (BulletId: ecs.entity_id) {
    bulletEntity := entity_create(true)

    bulletTransform, _ := ecs.add_component(&t_Transform, bulletEntity)
    bulletTransform.position = position
    bulletTransform.scale = scale

    bulletVelocity, _ := ecs.add_component(&t_Velocity, bulletEntity)
    normVelDir := rl.Vector2Normalize(direction)
    bulletVelocity.velocity = normVelDir * startSpeed
    bulletVelocity.deceleration_coeff = 1
    //Maybe set coeff ?

    bulletRenderer, _ := ecs.add_component(&t_SpriteRenderer, bulletEntity)
    bulletRenderer.sprite = resource.PrimitiveEllipse{}
    bulletRenderer.color = rl.GOLD

    ecs.add_component(&t_Cullable, bulletEntity)

    bulletStats, _ := ecs.add_component(&t_BulletStats, bulletEntity)
    bulletStats.speed = startSpeed
    bulletStats.damage = damage
    bulletStats.max_lifetime = lifetime

    //bulletHashData, _ := ecs.add_component(&t_HashableEntity, bulletEntity)
    //bulletHashData.type = { .BULLET }

    bulletCollider, _ := ecs.add_component(&t_Collider, bulletEntity)
    bulletCollider.offX = 3.75
    bulletCollider.offY = 3.75
    bulletCollider.offW = 2.5
    bulletCollider.offH = 2.5

    bulletCollisionChecker, _ := ecs.add_component(&t_CollisionChecker, bulletEntity)
    bulletCollisionChecker.type = .BoxCastCollision

    return bulletEntity
}