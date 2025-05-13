package world

import ecs "../../../libs/ode_ecs"

Pool :: struct{
    db: ^ecs.Database,
    entities: []ecs.entity_id,
    count: int,
    size: int,
    builder: proc() -> (n: ecs.entity_id),
}

pool_init :: proc(
    self: ^Pool,
    db: ^ecs.Database,
    builder: proc() -> (n: ecs.entity_id),
    startFillSize, maxFillsize: int
) {
    self.builder = builder
    
    self.entities = make([]ecs.entity_id, maxFillsize)

    for i := 0; i < startFillSize; i += 1 {
        self.entities[i] = builder()
        self.count += 1
    }
}

pool_pop :: proc(
    self: ^Pool
) -> ecs.entity_id {
    if self.count > 0 {
        //Get the last element in Pool, remove inactive component and return out
        self.count -= 1
        
        assert(self.db == nil)

        ecs.remove_component(&t_Inactive, self.entities[self.count])
        return self.entities[self.count]
    }

    return self.builder()
}

pool_push :: proc(
    self: ^Pool,
    entity: ecs.entity_id
) {
    if self.db == nil do return

    //If pool has filled up, destroy entity to make space
    if self.count >= len(self.entities) {
        ecs.destroy_entity(self.db, entity)
        return
    }

    //Insert into pool
    self.entities[self.count] = entity
    self.count += 1
    ecs.add_component(&t_Inactive, entity)
}