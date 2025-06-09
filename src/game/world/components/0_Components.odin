package components

import ecs "../../../../libs/ode_ecs"

/**
    GENERAL DATA STRUCTURES
*/

LogisticItem :: struct {
    itemid: cstring
}

/*
Initializes all components used in the ecs system
*/
init_components :: proc(
    db: ^ecs.Database,
    cap: int
) {
    ecs.table_init(&t_BoidParticle, db, cap)
    ecs.table_init(&t_BulletStats, db, cap)
    ecs.table_init(&t_Collider, db, cap)
    ecs.table_init(&t_CollisionChecker, db, cap)
    ecs.table_init(&t_Cullable, db, cap)
    ecs.table_init(&t_EnemyStats, db, cap)
    ecs.table_init(&t_GunStats, db, cap)
    ecs.table_init(&t_HashableEntity, db, cap)
    ecs.table_init(&t_MovementInput, db, cap)
    ecs.table_init(&t_MovementStats, db, cap)
    ecs.table_init(&t_PlayerStats, db, cap)
    ecs.table_init(&t_SpriteRenderer, db, cap)
    ecs.table_init(&t_State, db, cap)
    ecs.table_init(&t_Tags, db, cap)
    ecs.table_init(&t_Transform, db, cap)
    ecs.table_init(&t_TransformChild, db, cap)
    ecs.table_init(&t_TransformLookAt, db, cap)
    ecs.table_init(&t_Velocity, db, cap)
    ecs.table_init(&t_DebugInspectable, db, cap)
    ecs.table_init(&t_FactoryConveyor, db, cap)
    ecs.table_init(&t_SplineRenderer, db, cap)
    ecs.table_init(&t_ConveyorBuilder, db, cap)
    ecs.table_init(&t_ConveyorSnapPoint, db, cap)
    ecs.table_init(&t_LogisticIntake, db, cap)
    ecs.table_init(&t_LogisticOutput, db, cap)
}