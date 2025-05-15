package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"
import types "../../../../libs/datatypes"

@(private="file")
BulletPool: types.Pool(ecs.entity_id)

init_bullet :: proc() {
    types.pool_init(
        &BulletPool,
        1024,
        15,
        build_bullet,
        destroy_bullet
    )
}

spawn_bullet :: proc(
    startSpeed, damage, lifetime: f32,
    position, scale, direction: rl.Vector2
) {
    eid, _ := types.pool_pop(&BulletPool)

    state := ecs.get_component(&comps.t_State, eid)
    state ^= true

    bulletTransform := ecs.get_component(&comps.t_Transform, eid)
    bulletTransform.position = position
    bulletTransform.scale = scale

    bulletVelocity := ecs.get_component(&comps.t_Velocity, eid)
    normVelDir := rl.Vector2Normalize(direction)
    bulletVelocity.velocity = normVelDir * startSpeed
    bulletVelocity.deceleration_coeff = 1

    bulletStats:= ecs.get_component(&comps.t_BulletStats, eid)
    bulletStats.speed = startSpeed
    bulletStats.damage = damage
    bulletStats.max_lifetime = lifetime
}

@(private="file")
build_bullet :: proc() -> ecs.entity_id {
    bulletEntity := create_entity(false)

    bulletTransform, _ := ecs.add_component(&comps.t_Transform, bulletEntity)
    bulletVelocity, _ := ecs.add_component(&comps.t_Velocity, bulletEntity)
    bulletVelocity.deceleration_coeff = 1
    //Maybe set coeff ?

    bulletRenderer, _ := ecs.add_component(&comps.t_SpriteRenderer, bulletEntity)
    bulletRenderer.sprite = resource.PrimitiveEllipse{}
    bulletRenderer.color = rl.GOLD

    ecs.add_component(&comps.t_Cullable, bulletEntity)

    bulletStats, _ := ecs.add_component(&comps.t_BulletStats, bulletEntity)

    //bulletHashData, _ := ecs.add_component(&t_HashableEntity, bulletEntity)
    //bulletHashData.type = { .BULLET }

    bulletCollider, _ := ecs.add_component(&comps.t_Collider, bulletEntity)
    bulletCollider.offX = 3.75
    bulletCollider.offY = 3.75
    bulletCollider.offW = 2.5
    bulletCollider.offH = 2.5

    bulletCollisionChecker, _ := ecs.add_component(&comps.t_CollisionChecker, bulletEntity)
    bulletCollisionChecker.type = .BoxCastCollision

    return bulletEntity
}

@(private="file")
destroy_bullet :: proc(id: ecs.entity_id) {

}