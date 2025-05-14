package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "base:runtime"

import types "../datatypes"

//Common DataTypes
Renderable :: union {
    ^rl.Texture2D,
    SubImage,
    PrimitiveEllipse,
    PrimitvieRect
}

SubImage :: struct {
    tex: ^rl.Texture2D,
    srcRec: rl.Rectangle
}

PrimitvieRect :: struct {}
PrimitiveEllipse :: struct {}

//Common Functions

/*
Initializes the Resource Systems and it's Registries
*/
init_registries :: proc() {
    types.registry_init(&AnimationRegistry, UnloadAnimation)
    types.registry_init(&TextureRegistry, UnloadTexture)
    //registry_create(&ModifierRegistry, UnloadModifier)
}

/*
Destroys all Registires and their contents inside the Data System
*/
destroy_registries :: proc() {
    types.registry_destroy(&AnimationRegistry)
    types.registry_destroy(&TextureRegistry)
    //registry_destroy(&ModifierRegistry)
}