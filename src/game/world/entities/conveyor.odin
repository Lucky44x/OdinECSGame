package entities

package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"

/*
Creates a conveyor entity and starts the placement logic
*/
create_conveyor :: proc(
    startPos: rl.Vector2
) -> ecs.entity_id {
    convEntitiy := create_entity(true)

    convTransform, _ := ecs.add_component(&comps.t_Transform, convEntitiy)
    convTransform.position = startPos

    gunSpriteRenderer, _ := ecs.add_component(&comps.t_SpriteRenderer, gunEntity)
    gunSpriteRenderer.sprite = resource.PrimitvieRect{}
    gunSpriteRenderer.color = rl.BLACK

    ecs.add_component(&comps.t_Cullable, gunEntity)

    gunStats, _ := ecs.add_component(&comps.t_GunStats, gunEntity)
    gunStats.gunDamage = gunDamage
    gunStats.bulletSpeed = 25

    gunInput, _ := ecs.add_component(&comps.t_GunInput, gunEntity)
    gunInput.shootKey = rl.MouseButton.LEFT

    return gunEntity
}