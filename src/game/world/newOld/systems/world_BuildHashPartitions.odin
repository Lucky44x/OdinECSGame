package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"

@(private="file")
v_build_hash_partition: ecs.View
@(private="file")
it_build_hash_partition: ecs.Iterator

//Systems
s_build_hash_partion :: proc() {
    for ecs.iterator_next(&it_build_hash_partition) {
        eid := ecs.get_entity(&it_build_hash_partition)

        if !check_is_active(eid) do continue

        culled: ^comp.c_Cullable = ecs.get_component(&comp.t_Cullable, eid)
        if culled.culled do continue

        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        hashData: ^comp.c_HashableEntity = ecs.get_component(&comp.t_HashableEntity, eid)
        collider: ^comp.c_Collider = ecs.get_component(&comp.t_Collider, eid)

        /*
        hashKey := get_cell_hash_from_worldpos(transform.position)

        //Check if Bucket exists
        if ! (hashKey in DynamicEntities) {
            new_entities: #soa[]EntityDescriptor

            if freeListCount > 0 {
                new_entities = dynamicFreeList[freeListCount - 1]
                freeListCount -= 1
            } else {
                new_entities = #force_inline make(#soa[]EntityDescriptor, BUCKET_CAPACITY)
            }

            DynamicEntities[hashKey] = Bucket{
                count = 0,
                capacity = BUCKET_CAPACITY,
                entities = new_entities
            }
        }

        //Add our new Entry

        //Calculate velocity if applicable
        entityVelocity := rl.Vector2{}
        if EntityType.BOID in hashData.type {
            velocityComponent: ^c_Velocity = ecs.get_component(&t_Velocity, eid)
            entityVelocity = velocityComponent.velocity
        }

        //AABB Calculations
        renderPos := transform.position - (transform.origin * transform.scale)
        myAABB := rl.Rectangle{
            renderPos[0],
            renderPos[1],
            transform.scale[0],
            transform.scale[1]
        }

        if collider != nil {
            myAABB = collider.rect
        }


        bucketPtr := &DynamicEntities[hashKey]
        bucketPtr.empty_frame_counter = 0
        bucketPtr.entities[bucketPtr.count] = EntityDescriptor{
            eid = eid,
            pos = transform.position,
            vel = entityVelocity,
            aabb = myAABB,
            active = true,
            type = hashData.type
        }
        bucketPtr.count += 1
        */
    }

    ecs.iterator_reset(&it_build_hash_partition)
}