package tags

EntityTags :: enum{
    PLAYER,
    STATIC,
    BULLET,
    ENEMY,
    BOID,
    COLLIDES
}

TagContainer :: distinct bit_set[EntityTags]