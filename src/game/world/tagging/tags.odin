package tags

EntityTags :: enum{
    ANY,
    PLAYER,
    STATIC,
    BULLET,
    ENEMY,
    BOID,
    COLLIDES,
    SNAPPOINT
}

TagContainer :: distinct bit_set[EntityTags]