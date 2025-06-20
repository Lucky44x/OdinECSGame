package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"

import types "../../libs/datatypes"

@(private)
TextureRegistry: types.Registry(cstring, rl.Texture2D)
@(private)
TexturePathRegistry: types.Registry(string, cstring)

/*
Will load a Texture2D into the internal TextureRegistry, allowing the game to use it.
Textures can be used via Reference
*/
LoadTexture :: proc(
    path: cstring,
    id: string = ""
) -> ^rl.Texture2D {

    //Check if we already loaded this file previously
    alreadyLoaded, _ := types.registry_has(&TextureRegistry, path)

    //If so, get the reference and retunr it to the caller
    if alreadyLoaded {
        ref, _ := types.registry_get(&TextureRegistry, path)
        return ref
    }

    //If not, load the Texture and put it into the Registry and return its reference
    tex := rl.LoadTexture(path)
    ref, _ := types.registry_put(&TextureRegistry, path, tex)
    types.registry_put(&TexturePathRegistry, id, path)
    return ref
}

GetTextureByID :: proc(
    id: string
) -> ^rl.Texture2D {
    path, err := types.registry_get(&TexturePathRegistry, id)
    if err != nil do return nil

    val, err1 := types.registry_get(&TextureRegistry, path^)
    if err1 != nil do return nil

    return val
}

/*
Will Unload the provided Texture
*/
@(private)
UnloadTexture :: proc(tex: ^rl.Texture2D) { rl.UnloadTexture(tex^) }