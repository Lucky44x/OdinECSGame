package partioning

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import vmem "core:mem/virtual"
import "core:mem"
import "core:fmt"

import "core:math"
import "core:math/linalg"

import "../tagging"

//GENERAL

//General Data

/*
@(private="file") BUCKET_WIDTH :: 128
@(private="file") BUCKET_HEIGHT :: 128
@(private="file") BUCKET_CAPACITY :: 1024
@(private="file") MAX_FREE_BUCKETS :: 256
@(private="file") BUCKET_LIFETIME :: 120

@(private="file")
EntityDescriptor :: struct {
    eid: ecs.entity_id,
    pos, vel: rl.Vector2,
    aabb: rl.Rectangle,
    active: bool,
    tags: tagging.TagContainer
}

@(private="file")
Bucket :: struct {
    count: u32,
    capacity: u32,
    entities: #soa[]EntityDescriptor,
    empty_frame_counter: u8
}

@(private="file") dynamicFreeList: []#soa[]EntityDescriptor
@(private="file") freeListCount: u32

@(private="file") DynamicEntities: map[u64]Bucket
@(private="file") StaticEntities: map[u64]Bucket

//Behaviour Functions
get_collision_with_entity_cast :: proc(
    originalPosition, currentPosition: rl.Vector2,
    ownCollider: ^c_Collider,
    ownId: ecs.entity_id
) -> (other: ^c_Collider, otherId: ecs.entity_id) {
    movement := currentPosition - originalPosition
    movementDir := rl.Vector2Normalize(movement)

    stepSize : i32 = i32(min(ownCollider.rect.width, ownCollider.rect.height))
    steps : i32 = i32(math.ceil(rl.Vector2LengthSqr(movement) / f32(stepSize * stepSize)))

    collPosOffset := rl.Vector2{ownCollider.rect.x, ownCollider.rect.y} - currentPosition


    //Do a bounding box check
    boundingBox := rl.Rectangle{
        originalPosition[0],
        originalPosition[1],
        movement[0],
        movement[1]
    }

    //Check if there is anyhting inside our bounding box, if not, return early
    bounding, _ := check_rec_collision_with_entitties(ownId, boundingBox)
    if bounding == nil do return nil, ownId

    for step : i32 = 0; step < steps; step += 1 {
        //Will introduce some slight inconsitencies when close to an enemy or using a large collider, but eh, whatever
        
        //Here be dragons
        newPos := originalPosition + movementDir * f32(stepSize * step)

        newRecPos := newPos + collPosOffset
        stepRec := rl.Rectangle{
            newRecPos[0],
            newRecPos[1],
            ownCollider.rect.width,
            ownCollider.rect.height
        }

        //TODO: remove
        rl.DrawRectanglePro(stepRec, {0, 0}, 0, rl.PINK)

        bounding, id := check_rec_collision_with_entitties(ownId, stepRec)
        if bounding == nil do continue

        return bounding, id
    }

    return nil, ownId
}

do_cursed_conversion :: proc(
    originalVec: rl.Vector2
) -> rl.Vector3 {
    return { originalVec[0], originalVec[1], 0 }
}

check_rec_collision_with_entitties :: proc(
    ownId: ecs.entity_id,
    rect: rl.Rectangle
) -> (other: ^c_Collider, entity: ecs.entity_id) {
    myCell := get_cell_pos_from_worldpos({ rect.x, rect.y })
    startCell := myCell - { 1,1 }

    for cellX := startCell[0]; cellX < startCell[0] + 3; cellX += 1 {
        for cellY := startCell[1]; cellY < startCell[1] + 3; cellY += 1 {
            cellId := get_cell_hash_from_cellpos({ cellX, cellY })

            if is_cell_empty(cellId) do continue

            bucketPtr: ^Bucket = &DynamicEntities[cellId]
            for i: u32 = 0; i < bucketPtr.count; i += 1 {
                descriptor := &bucketPtr.entities[i]

                //If entity does not have collider, skip
                if EntityType.COLLIDES not_in descriptor.type do continue

                if rl.CheckCollisionRecs(rect, descriptor.aabb) {
                    otherCollider: ^c_Collider = ecs.get_component(&t_Collider, descriptor.eid)
                    return otherCollider, descriptor.eid
                }
            }
        }
    }

    return nil, ownId
}

get_boid_velocity_vector :: proc(
    transform, player_transform: ^c_Transform,
    perception_radius, player_perception_radius, seperation_weight, cohesion_weight, alignment_weight, player_weight: f32
) -> rl.Vector2 {
    //Calculate position of upper/left cell, next to my current cell
    myCell := get_cell_pos_from_worldpos(transform.position)
    startCell := myCell - { 3, 3 }

    alignment_force, cohesion_force, seperation_force: rl.Vector2 = {}, {}, {}
    center_of_mass: rl.Vector2 = {0, 0}
    cohesion_total_weight: f32 = 0

    //Iterate over all 9 Cells including current cell, as well as those around it
    for cellX := startCell[0]; cellX < startCell[0] + 6; cellX += 1 {
        for cellY := startCell[1]; cellY < startCell[1] + 6; cellY += 1 {
            cellId := get_cell_hash_from_cellpos({ cellX, cellY })

            //If this Cell is empty, skip it
            if is_cell_empty(cellId) do continue

            bucketPtr := &DynamicEntities[cellId]
            for i: u32 = 0; i < bucketPtr.count; i += 1 {
                descriptor := &bucketPtr.entities[i]

                //If entity is not of type BOID, skip it
                if EntityType.BOID not_in descriptor.type do continue

                //Calculate distance (Squared in order to skip the suqare root step..., should probably take some resource of the caclculation)
                distance := rl.Vector2DistanceSqrt(transform.position, descriptor.pos)
                
                //If outside perception radius, skip it
                if distance > (perception_radius * perception_radius) do continue

                weight := (distance / (perception_radius * perception_radius))
                weightInv := 1.0 - weight 
                
                
                seperation_force += rl.Vector2Normalize(transform.position - descriptor.pos) * (weightInv == 0 ? 0.001 : weightInv)
                alignment_force += rl.Vector2Normalize(descriptor.vel) * weightInv
                cohesion_force += rl.Vector2Normalize(descriptor.pos - transform.position) * weight
            }
        }
    }

    //Finished adding up all forces

    player_force: rl.Vector2 = {}
    playerDistance := rl.Vector2DistanceSqrt(player_transform.position, transform.position)
    if playerDistance <= (player_perception_radius*player_perception_radius) {
        weight := 1.0 - (playerDistance / (player_perception_radius * player_perception_radius))
        player_force = (player_transform.position - transform.position) * weight
    }

    return (seperation_force * seperation_weight) +
    (alignment_force * alignment_weight) +
    (cohesion_force * cohesion_weight) +
    (player_force * player_weight)

    /*
    return rl.Vector2Normalize(
        (seperation_force * seperation_weight) +
        (alignment_force * alignment_weight) +
        (cohesion_force * cohesion_weight) +
        (player_force * player_weight)
    )
    */
}

//General functions
/*
Calculates, and returns the cell position from a World-Position
*/
get_cell_pos_from_worldpos :: proc(
    worldPos: rl.Vector2
) -> rl.Vector2 {
    cellX := i32(worldPos[0]) / BUCKET_WIDTH
    cellY := i32(worldPos[1]) / BUCKET_HEIGHT
    return { f32(cellX), f32(cellY) }
}

/*
Calculates, and returns the cell position hash from a World-Position
*/
get_cell_hash_from_worldpos :: proc(
    worldPos: rl.Vector2
) -> u64 {
    cellX := i32(worldPos[0]) / BUCKET_WIDTH
    cellY := i32(worldPos[1]) / BUCKET_HEIGHT
    return #force_inline u64(cellY) << 32 | u64(u32(cellX))
}

/*
Calculates, and returns the cell position hash from a Cell-Position
*/
get_cell_hash_from_cellpos :: proc(
    cellPos: rl.Vector2
) -> u64 {
    return #force_inline u64(cellPos[1]) << 32 | u64(u32(cellPos[0]))
}

/*
Retruns true if a cell is empty, or doesn't exist
*/
is_cell_empty :: proc(
    id: u64
) -> bool {
    if !(id in DynamicEntities) do return true
    if DynamicEntities[id].count == 0 do return true
    return false
}

/*
Initializes the hash-partioning Datastructures and it's repsective components, tables and systems
*/
init_comp_hashed_space_partition :: proc(
    db: ^ecs.Database
) {
    /*
    arena = vmem.Arena{}
    _ = vmem.arena_init_growing(&arena)
    arena_alloc = vmem.arena_allocator(&arena)
    */

    freeListCount = 0
    dynamicFreeList = make([]#soa[]EntityDescriptor, MAX_FREE_BUCKETS)

    ecs.table_init(&t_HashableEntity, db, 5000)
    
    ecs.view_init(&v_HashEntities, db, {&t_HashableEntity, &t_Transform, &t_Cullable})
    ecs.iterator_init(&it_HashEntities, &v_HashEntities)
    DynamicEntities = make_map(map[u64]Bucket)
    StaticEntities = make_map(map[u64]Bucket)
}

/*
Deinit hash-partionioning structures
*/
comp_deinit_hashed_space_partition :: proc() {
    //free_all(arena_alloc)

    for i : u32 = 0; i < freeListCount; i += 1 {
        delete(dynamicFreeList[i])
    }

    for key, bucket in DynamicEntities {

        //This line throws a bad free error during shutdown and causes a crash (probably something that gets cleared 2 times (once in the freelist and once in the actual map))
        delete(bucket.entities)
        delete_key(&DynamicEntities, key)
    }

    delete(dynamicFreeList)
    delete_map(DynamicEntities)
    delete_map(StaticEntities)
}

/*
Clears the map of dynamic entities, essentially resetting the collision map
*/
clear_spatial_partition_data :: proc() {
    for key, &bucket in DynamicEntities {
        if bucket.count == 0 {
            if bucket.empty_frame_counter >= BUCKET_LIFETIME {

                if freeListCount < MAX_FREE_BUCKETS {
                    dynamicFreeList[freeListCount] = bucket.entities
                    freeListCount += 1
                } else {
                    delete(bucket.entities)
                }

                delete_key(&DynamicEntities, key)
            }
            bucket.empty_frame_counter += 1
            //If already 0, nothing has passed into this cell since last frame, so we delete it
        }
        bucket.count = 0
    }
}

/*
Displays the "Buckets" as outlines inside the world view
*/
debug_bucket_display :: proc() {
    for key, entry in DynamicEntities {
        cellX := i32(key & 0xFFFFFFFF)
        cellY := i32(key >> 32)
    
        drawCol: rl.Color = rl.LIME
        if entry.empty_frame_counter > BUCKET_LIFETIME / 2 do drawCol = rl.RED
        else if entry.empty_frame_counter > 0 do drawCol = rl.ORANGE

        rl.DrawRectangleLines(cellX * BUCKET_WIDTH, cellY * BUCKET_HEIGHT, BUCKET_WIDTH, BUCKET_HEIGHT, drawCol)

        for i : u32 = 0; i < entry.count; i += 1 {
            rl.DrawRectangleLinesEx(entry.entities[i].aabb, 2, rl.PURPLE)
        }
    }

    rl.DrawText(rl.TextFormat("Freelist: %i", freeListCount), 25, 100, 25, rl.MAROON)
}
    */