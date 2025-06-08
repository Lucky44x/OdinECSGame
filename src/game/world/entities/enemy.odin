package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"
import types "../../../../libs/datatypes"
import "../tagging"
import "core:fmt"

import contextmenu "../../ui/contextmenu/items"

@(private="file")
EnemyPool: types.Pool(ecs.entity_id, 1024)

init_enemy :: proc() {
    types.pool_init(
        &EnemyPool, 
        25,
        build_enemy,
        destroy_enemy
    )

    contextmenu.register_world_item({
        label = "Spawn Enemy",
        option = command_spawn_enemy
    })

    fmt.printfln("Finished loading")
}

deinit_enemy :: proc() {
    types.pool_destroy(&EnemyPool)
}

spawn_enemy :: proc(
    position, scale: rl.Vector2,
    target: ^comps.c_Transform
) {
    eid, err := types.pool_pop(&EnemyPool)
    
    poscomp : ^comps.c_Transform = ecs.get_component(&comps.t_Transform, eid)
    poscomp.position = position
    poscomp.scale = scale

    lookatcomp : ^comps.c_TransformLookAt = ecs.get_component(&comps.t_TransformLookAt, eid)
    lookatcomp.target = target

    activecomp : ^comps.c_State = ecs.get_component(&comps.t_State, eid)
    activecomp ^= true
}

kill_enemy :: proc(
    eid: ecs.entity_id
) {
    types.pool_push(&EnemyPool, eid)
    activecomp : ^comps.c_State = ecs.get_component(&comps.t_State, eid)
    activecomp ^= false
}

@(private="file")
build_enemy :: proc() -> ecs.entity_id {
    fmt.printfln("Building new Enemey")

    eid := create_entity(false)
    transform, _ := ecs.add_component(&comps.t_Transform, eid)
    velocity, _ := ecs.add_component(&comps.t_Velocity, eid)
    lookat, _ := ecs.add_component(&comps.t_TransformLookAt, eid)
    renderer, _ := ecs.add_component(&comps.t_SpriteRenderer, eid)
    renderer.sprite = resource.PrimitiveEllipse{}
    renderer.color = rl.RED
    movestats, _ := ecs.add_component(&comps.t_MovementStats, eid)
    hashdata, _ := ecs.add_component(&comps.t_HashableEntity, eid)
    //boid, _ :=  ecs.add_component(&comps.t_BoidParticle, eid)
    collider, _ := ecs.add_component(&comps.t_Collider, eid)
    tags, _ := ecs.add_component(&comps.t_Tags, eid)
    tags ^= { tagging.EntityTags.BOID, tagging.EntityTags.ENEMY, tagging.EntityTags.COLLIDES }
    cullable, _ := ecs.add_component(&comps.t_Cullable, eid)

    when ODIN_DEBUG {
        debug_inspectable, _ := ecs.add_component(&comps.t_DebugInspectable, eid)
        debug_inspectable.collisionSize = { 30, 30 }
        debug_inspectable.collisionOffset = { -1, -1 }
        debug_inspectable.menu = {
            title = "Enemy",
            items = make([]contextmenu.ContextMenuItem, 2)
        }
        debug_inspectable.menu.items[0] = {
            label = "Kill",
            option = command_kill_enemy
        }
        debug_inspectable.menu.items[1] = {
            label = "Close",
            option = proc(){ contextmenu.close_current_context_menu() }
        }
    }

    return eid
}

@(private="file")
destroy_enemy :: proc(
    eid: ecs.entity_id
) {
    when ODIN_DEBUG {
        inspectable: ^comps.c_DebugInspectable = ecs.get_component(&comps.t_DebugInspectable, eid)
        delete(inspectable.menu.items)
    }

    destroy_entity(eid)
}

/**
    COMMANDS
*/

@(private="file")
command_kill_enemy :: proc(
    db: ^ecs.Database,
    eid: ecs.entity_id
) {
    kill_enemy(eid)
    contextmenu.close_current_context_menu()
}

@(private="file")
command_spawn_enemy :: proc(
    pos: rl.Vector2
) {
    spawn_enemy(pos, { 15, 15 }, player_transform_ref)
    contextmenu.close_current_context_menu()
}