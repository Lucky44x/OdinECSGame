package world

import ecs "../../../libs/ode_ecs"
import rl "vendor:raylib"

@(private="file") ecs_world: ecs.Database

/*
Initialize World, as well as all ECS-Related Structures in the background
*/
init_world :: proc() {
    ecs.init(&ecs_world, entities_cap=5000)

    camera_init()

    //Init the different Tables
    init_comp_general(&ecs_world)
    init_comp_collision(&ecs_world)
    init_comp_hashed_space_partition(&ecs_world)
    init_comp_boids(&ecs_world)
    init_comp_player(&ecs_world)
    init_comp_gun(&ecs_world)
    init_comp_bullet(&ecs_world)
    init_comp_enemy(&ecs_world)
    init_comp_collision_resolution(&ecs_world)

    //Init the rest of the world
    playerID, _ := player_create({100,100}, {25,25}, 5, 5, 5)
    playerTransform: ^c_Transform = ecs.get_component(&t_Transform, playerID)

    //Create enemies
    enemy_spawn({500, 250}, {25, 25}, 5, playerTransform)
    enemy_spawn({550, 250}, {25, 25}, 5, playerTransform)
    enemy_spawn({600, 250}, {25, 25}, 5, playerTransform)
    enemy_spawn({650, 250}, {25, 25}, 5, playerTransform)
    enemy_spawn({500, 300}, {25, 25}, 5, playerTransform)
    enemy_spawn({550, 300}, {25, 25}, 5, playerTransform)
    enemy_spawn({600, 300}, {25, 25}, 5, playerTransform)
    enemy_spawn({650, 300}, {25, 25}, 5, playerTransform)
    enemy_spawn({500, 350}, {25, 25}, 5, playerTransform)
    enemy_spawn({550, 350}, {25, 25}, 5, playerTransform)
    enemy_spawn({600, 350}, {25, 25}, 5, playerTransform)
    enemy_spawn({650, 350}, {25, 25}, 5, playerTransform)
    enemy_spawn({500, 400}, {25, 25}, 5, playerTransform)
    enemy_spawn({550, 400}, {25, 25}, 5, playerTransform)
    enemy_spawn({600, 400}, {25, 25}, 5, playerTransform)
    enemy_spawn({650, 400}, {25, 25}, 5, playerTransform)
}

/*
Deinitializes the world and it's contents
*/
deinit_world :: proc() {
    comp_deinit_hashed_space_partition()
}

/*
Will execute all logical systems once
*/
do_logic_systems :: proc() {
    camera_update() //General Updates

    //Input phase
    s_gun_input()
    s_movementInput()

    //Culling phase
    s_cull_entities()

    //Hash + Boids
    s_hash_entity_positions()
    s_do_boid_update()

    //Enemy Logic phase (apply enemy specific speed and such to boid steering vector)
    s_do_enemy_boid_movement()

    //Velocity Application and transform phase
    s_apply_velocity()
    s_children_transform_update()

    s_transform_lookat_target()

    //Rehash phase
    clear_spatial_partition_data()
    s_hash_entity_positions()

    //Collision and collision handle phase
    s_collider_update()
    s_collision_checker()

    s_resolve_collisions()
}

/*
Will execute all drawing systems once
*/
do_drawing_systems :: proc() {
 
    rl.BeginMode2D(GameCamera)

    //rl.DrawCircle(1280/2, 720/2, 25, rl.PURPLE)

    s_sprite_renderer_render()

    debug_bucket_display()

    debug_draw_colliders()

    rl.EndMode2D()

    clear_spatial_partition_data()
}

/*
Creates a new Entity and returns it's entityID Handle for the ECS-World
*/
@(private)
entity_create :: proc() -> ecs.entity_id {
    ent: ecs.entity_id
    ent, _ = ecs.create_entity(&ecs_world)
    return ent
}