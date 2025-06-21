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

/*
    INTERFACING FUNCTIONS
*/
get_snappoint :: proc(
    self: ^HashedPartionMap,
    ownPosition: rl.Vector2,
    searchFor: comp.SNAPTYPE = .General
) -> (found: bool, position: rl.Vector2, direction: f32, type: comp.SNAPTYPE, eid: ecs.entity_id) {
    profiling.profile_scope("HashPartition GetSnapPoint")

    //check a 3x3 area around our own Bucket, with a cell size of 512 this should be plenty
    ownBucketPos := get_bucket_pos_from_worldpos(self, ownPosition)
    for x := ownBucketPos[0] - 1; x < ownBucketPos[0] + 1; x += 1 {
        for y := ownBucketPos[1] - 1;y < ownBucketPos[1] + 1; y += 1 {
            currentBucketHash := get_bucket_hash_from_cellpos({ x, y })
            if is_bucket_empty(self, currentBucketHash, { tagging.EntityTags.SNAPPOINT }) do continue

            //Loop over entities inside this bucket
            currentBucket: ^HashBucket = get_bucket_from_hash(self, currentBucketHash)
            
            for u: u16 = 0; u < currentBucket.taggedIndecies[tagging.EntityTags.SNAPPOINT]; u += 1 {
                i := currentBucket.taggedLookup[tagging.EntityTags.SNAPPOINT][u]
                
                descriptor := currentBucket.entities[i]

                if searchFor != .General && u8(descriptor.aabb.height) != u8(searchFor) do continue

                distance := rl.Vector2DistanceSqrt(ownPosition, descriptor.pos)
                if distance > (descriptor.aabb.width * descriptor.aabb.width) do continue

                return true, descriptor.pos, descriptor.rotation, cast(comp.SNAPTYPE)descriptor.aabb.height, descriptor.eid
            }
        }
    }
    return false, {}, 0, .General, {}
}