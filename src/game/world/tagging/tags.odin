package tags

EntityTags :: enum{
    PLAYER,
    STATIC,
    BULLET,
    ENEMY,
    BOID,
    COLLIDES,
    SNAPPOINT
}

TagContainer :: distinct bit_set[EntityTags]