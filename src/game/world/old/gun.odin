package world

import rl "vendor:raylib"
import "../../resource"
import ecs "../../../libs/ode_ecs"

//General Data

//Components
@(private="file")


@(private="file")


//Tables
@(private="file") t_GunStats: ecs.Table(c_GunStats)
@(private="file") t_GunInput: ecs.Table(c_GunInput)

//Views
@(private="file") v_GunInput: ecs.View
@(private="file") it_GunInput: ecs.Iterator

//Systems

//General functions
/*
Initializes the gun-specific component Tables
*/
init_comp_gun :: proc(
    db: ^ecs.Database
) {
    ecs.table_init(&t_GunStats, db, 5000)
    ecs.table_init(&t_GunInput, db, 5000)

    ecs.view_init(&v_GunInput, db, { &t_GunStats, &t_GunInput, &t_Transform })
    ecs.iterator_init(&it_GunInput, &v_GunInput)
}

/*
Creates the Gun Entity and returns it's handle id
*/
gun_create :: proc(
    playerID: ecs.entity_id,
    gunDamage: f32
) -> ecs.entity_id {
    playerTransform := ecs.get_component(&t_Transform, playerID)
    gunEntity := entity_create(true)

    gunTransform, _ := ecs.add_component(&t_Transform, gunEntity)
    gunTransform.origin = rl.Vector2{0.5 , 0}
    
    gunTransformChild, _ := ecs.add_component(&t_TransformChild, gunEntity)
    gunTransformChild.parent = playerTransform
    gunTransformChild.offsetPosition = { 0, 0 }
    gunTransformChild.offsetScale = { 0.35, 1.5 }

    gunSpriteRenderer, _ := ecs.add_component(&t_SpriteRenderer, gunEntity)
    gunSpriteRenderer.sprite = resource.PrimitvieRect{}
    gunSpriteRenderer.color = rl.BLACK

    ecs.add_component(&t_Cullable, gunEntity)

    gunStats, _ := ecs.add_component(&t_GunStats, gunEntity)
    gunStats.gunDamage = gunDamage
    gunStats.bulletSpeed = 25

    gunInput, _ := ecs.add_component(&t_GunInput, gunEntity)
    gunInput.shootKey = rl.MouseButton.LEFT

    return gunEntity
}