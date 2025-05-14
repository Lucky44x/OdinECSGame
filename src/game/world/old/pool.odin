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
    self.db = db
    
    //TODO: Clear at deinit call
    self.entities = make([]ecs.entity_id, maxFillsize)

    for i := 0; i < startFillSize; i += 1 {
        self.entities[i] = builder()
        self.count += 1
    }
}

pool_pop :: proc(
    self: ^Pool
) -> ecs.entity_id {
    poppedEID: ecs.entity_id

    if self.count <= 0 {
        pool_push(self, self.builder())
    }

    self.count -= 1
    poppedEID = self.entities[self.count]

    state: ^c_State = ecs.get_component(&t_State, poppedEID)
    state ^= true

    return poppedEID
}

pool_push :: proc(
    self: ^Pool,
    entity: ecs.entity_id
) {
    assert(self.db != nil, "The Database was not set for this Pool")

    //If pool has filled up, destroy entity to make space
    if self.count >= len(self.entities) {
        ecs.destroy_entity(self.db, entity)
        return
    }

    //Change entity state to inactive
    state: ^c_State = ecs.get_component(&t_State, entity)
    state ^= false

    //Insert into pool
    self.entities[self.count] = entity
    self.count += 1
}