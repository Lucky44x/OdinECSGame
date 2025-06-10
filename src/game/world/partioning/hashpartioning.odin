package partioning

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import vmem "core:mem/virtual"
import types "../../../../libs/datatypes"
import "core:mem"
import "core:fmt"

import "core:math"
import "core:math/linalg"

import "../tagging"
import comp "../components"

import "../../profiling"

//GENERAL

MAX_ENTITIES_PER_BUCKET :: 1024
MAX_FREE_BUCKETS :: 256

HashedPartionMap :: struct {
    bucketWidth, bucketHeight: i32,
    bucketLifetime: u8,
    freeBucketPool: types.Pool(^HashBucket, MAX_FREE_BUCKETS),
    bucketMap: map[u64]^HashBucket
}

@(private="file")
HashBucket :: struct {
    count: u16,
    capacity: u32,
    entities: #soa[]EntityDescriptor,
    taggedLookup: [tagging.EntityTags][MAX_ENTITIES_PER_BUCKET]u16,
    taggedIndecies: [tagging.EntityTags]u16,
    empty_frame_counter: u8
}

@(private="file")
EntityDescriptor :: struct {
    eid: ecs.entity_id,
    pos, vel: rl.Vector2,
    aabb: rl.Rectangle,
    active: bool,
    tags: tagging.TagContainer
}

/*
    STRUCTURE FUNCTIONS
*/

init_spatial_hashing :: proc(
    self: ^HashedPartionMap,
    bucketWidth, bucketHeight: i32,
    bucketLifetime: u8
) {
    types.pool_init(
        &self.freeBucketPool, 
        10, 
        build_hash_bucket,
        destroy_hash_bucket
    )

    self.bucketHeight = bucketHeight
    self.bucketWidth = bucketWidth
    self.bucketLifetime = bucketLifetime
}

deinit_spatial_partitioning :: proc(
    self: ^HashedPartionMap
) {
    types.pool_destroy(&self.freeBucketPool)
    for _, bucket in self.bucketMap {
        destroy_hash_bucket(bucket)
    }
    delete(self.bucketMap)
}

@(private="file")
build_hash_bucket :: proc() -> ^HashBucket {
    newBucket, err := new(HashBucket)
    newBucket.entities = make(#soa[]EntityDescriptor, MAX_ENTITIES_PER_BUCKET)
    for tag in tagging.EntityTags do newBucket.taggedIndecies[tag] = 0

    return newBucket
}

@(private="file")
destroy_hash_bucket :: proc(
    bucket: ^HashBucket
) {
    //fmt.printfln("Freeing bucket %p", bucket)
    delete(bucket.entities)
    free(bucket)
}

/*
    PARTIONING FUNCTIONS
*/

/*
Clears the hashed-partition data
*/
clear_partition_data :: proc(
    self: ^HashedPartionMap
) {
    profiling.profile_scope("HashPartition ClearData")

    for key, &bucket in self.bucketMap {
        bucket.count = 0
        for tag in tagging.EntityTags do bucket.taggedIndecies[tag] = 0
    }
}

/*
Inserts this entity into the hashed-world-partition map (The entity will be included in collision and BOID calculations)
*/
insert_entity :: proc(
    self: ^HashedPartionMap,
    eid: ecs.entity_id
) {
    profiling.profile_scope("InsertEntity Function")

    transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
    hashData: ^comp.c_HashableEntity = ecs.get_component(&comp.t_HashableEntity, eid)

    hashKey := get_bucket_hash_from_worldpos(self, transform.position)
    bucket := get_bucket_from_hash(self, hashKey)

    eVel := rl.Vector2{}
    if ecs.has_component(&comp.t_Velocity, eid) {
        velComp : ^comp.c_Velocity = ecs.get_component(&comp.t_Velocity, eid)
        eVel = velComp.velocity
    }

    renderPos := transform.position - (transform.origin * transform.scale)
    aabb := rl.Rectangle {
        renderPos[0],
        renderPos[1],
        transform.scale[0],
        transform.scale[1]
    }
    if ecs.has_component(&comp.t_Collider, eid) {
        colComp : ^comp.c_Collider = ecs.get_component(&comp.t_Collider, eid)
        aabb = colComp.rect
    }

    tags : tagging.TagContainer = {}
    if ecs.has_component(&comp.t_Tags, eid) {
        tagsComp: ^comp.c_Tags = ecs.get_component(&comp.t_Tags, eid)
        tags = tagsComp^
    }

    //Create entity descriptor
    entityDescriptor := EntityDescriptor{
        eid = eid,
        pos = transform.position,
        vel = eVel,
        aabb = aabb,
        active = true,
        tags = tags
    }

    //Insert into bucket
    bucket.empty_frame_counter = 0
    bucket.entities[bucket.count] = entityDescriptor
    
    //Insert into tagging lookup lists
    for tag in tags {
        bucket.taggedLookup[tag][bucket.taggedIndecies[tag]] = bucket.count
        bucket.taggedIndecies[tag] += 1
    }

    //Increment count index
    bucket.count += 1
}

/*
Updates the bucketmap to destroy buckets that are overdue
*/
update_buckets :: proc(
    self: ^HashedPartionMap
) {
    profiling.profile_scope("HashPartition Bucket Update")

    for key, bucket in self.bucketMap {
        if bucket.count == 0 {            
            if bucket.empty_frame_counter >= self.bucketLifetime {
                //Push onto free map (if full, it gets destroyed)
                types.pool_push(&self.freeBucketPool, bucket)
                delete_key(&self.bucketMap, key)
            }

            bucket.empty_frame_counter += 1
        }
    }
}

/*
    INTERFACING FUNCTIONS
*/
get_boid_vector :: proc(
    self: ^HashedPartionMap,
    own_entity: ecs.entity_id
) -> rl.Vector2 {
    profiling.profile_scope("HashPartition GetBoidVector")

    ownTransform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, own_entity)
    ownBoid: ^comp.c_BoidParticle = ecs.get_component(&comp.t_BoidParticle, own_entity)

    //Initialize forces
    alignment_force, cohesion_force, seperation_force: rl.Vector2
    center_of_mass: rl.Vector2
    cohesion_total_weigt: f32

    //check a 3x3 area around our own Bucket, with a cell size of 512 this should be plenty
    ownBucketPos := get_bucket_pos_from_worldpos(self, ownTransform.position)
    for x := ownBucketPos[0] - 1; x < ownBucketPos[0] + 1; x += 1 {
        for y := ownBucketPos[1] - 1;y < ownBucketPos[1] + 1; y += 1 {
            currentBucketHash := get_bucket_hash_from_cellpos({ x, y })
            if is_bucket_empty(self, currentBucketHash) do continue

            //Loop over entities inside this bucket
            currentBucket: ^HashBucket = get_bucket_from_hash(self, currentBucketHash)
            
            for u: u16 = 0; u < currentBucket.taggedIndecies[tagging.EntityTags.BOID]; u += 1 {
                i := currentBucket.taggedLookup[tagging.EntityTags.BOID][u]
                
                descriptor := currentBucket.entities[i]
                if descriptor.eid == own_entity || !descriptor.active do continue   //Skip if self or inactive

                distance := rl.Vector2DistanceSqrt(ownTransform.position, descriptor.pos)
                //if distance >= 
            }
        }
    }
    return { 0, 0 }
}

/*
    GENNERAL FUNCTIONS
*/

/*
Gets the Bucket at the specified hash
*/
get_bucket_from_hash :: proc(
    self: ^HashedPartionMap,
    hash: u64
) -> ^HashBucket {
    //If Bucket is not in map, insert
    if hash not_in self.bucketMap {
        newBucket, err := types.pool_pop(&self.freeBucketPool)
        assert(err == nil, "Error during pull from free-pool... please investigate")
        newBucket.count = 0
        newBucket.capacity = MAX_ENTITIES_PER_BUCKET
        newBucket.empty_frame_counter = 0
        for tag in tagging.EntityTags do newBucket.taggedIndecies[tag] = 0
        self.bucketMap[hash] = newBucket
    }

    return self.bucketMap[hash]
}

/*
Calculates, and returns the cell position from a World-Position
*/
get_bucket_pos_from_worldpos :: proc(
    self: ^HashedPartionMap,
    worldPos: rl.Vector2
) -> rl.Vector2 {
    cellX := i32(worldPos[0]) /  self.bucketWidth
    cellY := i32(worldPos[1]) / self.bucketHeight
    return { f32(cellX), f32(cellY) }
}

/*
Calculates, and returns the cell position hash from a World-Position
*/
get_bucket_hash_from_worldpos :: proc(
    self: ^ HashedPartionMap,
    worldPos: rl.Vector2
) -> u64 {
    cellX := i32(worldPos[0]) / self.bucketWidth
    cellY := i32(worldPos[1]) / self.bucketHeight
    return #force_inline u64(cellY) << 32 | u64(u32(cellX))
}

/*
Calculates, and returns the cell position hash from a Cell-Position
*/
get_bucket_hash_from_cellpos :: proc(
    cellPos: rl.Vector2
) -> u64 {
    return #force_inline u64(cellPos[1]) << 32 | u64(u32(cellPos[0]))
}

/*
Retruns true if a cell is empty, or doesn't exist
*/
is_bucket_empty :: proc(
    self: ^HashedPartionMap,
    id: u64
) -> bool {
    if !(id in self.bucketMap) do return true
    if get_bucket_from_hash(self, id).count == 0 do return true
    return false
}

/*
    DEBUG DRAWING
*/

draw_bucket_map :: proc(
    self: ^HashedPartionMap
) {
    profiling.profile_scope("HashPartition DebugRender")

    for key, bucket in self.bucketMap {
        cellX := i32(key & 0xFFFFFFFF)
        cellY := i32(key >> 32)

        drawCol: rl.Color = rl.LIME
        if bucket.empty_frame_counter > self.bucketLifetime / 2 do drawCol = rl.RED
        else if bucket.empty_frame_counter > 0 do drawCol = rl.ORANGE

        rl.DrawRectangleLines(cellX * self.bucketWidth, cellY * self.bucketHeight, self.bucketWidth, self.bucketHeight, drawCol)
    }
}