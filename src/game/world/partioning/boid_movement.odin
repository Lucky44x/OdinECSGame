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
            if is_bucket_empty(self, currentBucketHash, { tagging.EntityTags.BOID }) do continue

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