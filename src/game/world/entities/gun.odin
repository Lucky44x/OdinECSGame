package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

/*
Creates the Gun Entity and returns it's handle id
*/
create_gun :: proc(
    playerID: ecs.entity_id,
    gunDamage: f32
) -> ecs.entity_id {
    playerTransform := ecs.get_component(&comps.t_Transform, playerID)
    gunEntity := create_entity(true)

    gunTransform, _ := ecs.add_component(&comps.t_Transform, gunEntity)
    gunTransform.origin = rl.Vector2{0.5 , 0}
    
    gunTransformChild, _ := ecs.add_component(&comps.t_TransformChild, gunEntity)
    gunTransformChild.parent = playerTransform
    gunTransformChild.offsetPosition = { 0, 0 }
    gunTransformChild.offsetScale = { 0.35, 1.5 }

    gunSpriteRenderer, _ := ecs.add_component(&comps.t_SpriteRenderer, gunEntity)
    gunSpriteRenderer.sprite = resource.PrimitvieRect{}
    gunSpriteRenderer.color = rl.BLACK

    ecs.add_component(&comps.t_Cullable, gunEntity)

    gunStats, _ := ecs.add_component(&comps.t_GunStats, gunEntity)
    gunStats.gunDamage = gunDamage
    gunStats.bulletSpeed = 25

    return gunEntity
}