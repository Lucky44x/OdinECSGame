package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"

import "core:encoding/json"

import types "../../libs/datatypes"

TextureID :: distinct u32

Texture :: union {
    rl.Texture2D,
    TextureAtlas,
    SubTexture
}

TextureAtlas :: struct {
    cell_size, atlas_size: rl.Vector2,
    src: rl.Texture2D
}

SubTexture :: struct {
    is_relative: bool,
    offset: rl.Vector2,
    src: TextureID
}

@(private)
TextureRegistry: types.Registry(TextureID, Texture)
@(private)
TexturePathRegistry: types.Registry(string, TextureID)

@(private)
NextTextureId: TextureID = 0

GetTextureByID :: proc(
    id: TextureID
) -> ^Texture {
    val, err := types.registry_get(&TextureRegistry, id)
    if err != nil do return nil

    return val
}

GetTextureByPath :: proc(
    path: string,
) -> ^Texture {
    id, err := GetTextureIDByPath(path)
    if err != nil do return nil
    return GetTextureByID(id^)
}

GetTextureIDByPath :: proc(
    path: string
) -> (id: ^TextureID, err: types.Error) {
    return types.registry_get(&TexturePathRegistry, path)
}

InsertTexture :: proc(
    id: string,
    texture: Texture
) {
    newID, idErr := types.registry_put(&TexturePathRegistry, id, NextTextureId)
    newTexture, itemErr := types.registry_put(&TextureRegistry, newID^, texture)
    NextTextureId += 1

    assert(itemErr == nil, "Error during texture insertion")
}

LoadAllTextures :: proc(
    dir, name_suffix: string
) {
    suffix := strings.join({ "*", name_suffix, ".json" }, "")
    defer delete(suffix)

    pattern := filepath.join({dir, suffix}, context.temp_allocator)
    //fmt.printfln("pattern: %s", pattern)
    found, err := filepath.glob(pattern, context.temp_allocator)
    //fmt.printfln("Found textures: %s", found)
    for path in found do LoadTexture(path)
}

LoadTexture :: proc(
    path: string
) {
    fileData, err := os.read_entire_file(path)
    defer delete(fileData)
    
    jsonData, jErr := json.parse(fileData)
    defer json.destroy_value(jsonData)

    texture_obj := jsonData.(json.Object)
    texture_id := texture_obj["id"].(json.String)
    texture_type := texture_obj["type"].(json.String)
    texture_src := texture_obj["src"].(json.String)

    //Generate Root path from filepath
    root_path := filepath.dir(path)
    defer delete(root_path)

    src_path_s := filepath.join({ root_path, texture_src })
    defer delete(src_path_s)
    src_path_c := strings.clone_to_cstring(src_path_s)
    defer delete(src_path_c)

    toAdd: Texture

    switch texture_type {
        case "atlas":
                texSizeArr := texture_obj["texture-size"].(json.Array)
                texSize: rl.Vector2 = { auto_cast texSizeArr[0].(json.Float), auto_cast texSizeArr[1].(json.Float) }

                atlasSizeArr := texture_obj["atlas-size"].(json.Array)
                atSize: rl.Vector2 = { auto_cast atlasSizeArr[0].(json.Float), auto_cast atlasSizeArr[1].(json.Float) }

                toAdd = TextureAtlas {
                    src = rl.LoadTexture(src_path_c),
                    atlas_size = atSize,
                    cell_size = texSize
                }
            break
        case "subtexture":
            offset_type := texture_obj["offset_type"].(json.String)
            offsetArr := texture_obj["offset"].(json.Array)
            offset: rl.Vector2 = { auto_cast offsetArr[0].(json.Float), auto_cast offsetArr[1].(json.Float) }
            texID, err := GetTextureIDByPath(texture_src)
            if err != nil do fmt.printfln("Error while trying to get id for texture %s, %e", texture_src, err)

            toAdd = SubTexture {
                offset = offset,
                is_relative = offset_type == "relative",
                src = texID^
            }

            break
        case "texture":
            toAdd = rl.LoadTexture(src_path_c)
            break
    }

    InsertTexture(strings.clone(texture_id), toAdd)

    when ODIN_DEBUG {
        newID, err2 := GetTextureIDByPath(texture_id)
        fmt.printfln("Loaded Texture \"%s\" as \"%s\" with numeric id %i", texture_id, texture_id, newID^)
        fmt.printfln("Texture-Data: %s", GetTextureByID(newID^)^)
    }

    LOADED_FILES += 1
}

get_src_rec :: proc {
    texture_get_src_rec,
    subtexture_get_src_rec
}

@(private)
texture_get_src_rec :: proc(
    texture: ^rl.Texture2D,
    loc := #caller_location
) -> rl.Rectangle {
    return {
        0, 0, auto_cast texture.width, auto_cast texture.height
    }
}

@(private)
subtexture_get_src_rec :: proc(
    subtexture: ^SubTexture,
    loc := #caller_location
) -> rl.Rectangle {
    parentTex := GetTextureByID(subtexture.src)
    parentAtlas := cast(^TextureAtlas)parentTex

    if subtexture.is_relative && (subtexture.offset[0] > parentAtlas.atlas_size[0] || subtexture.offset[1] > parentAtlas.atlas_size[1] || subtexture.offset[0] < 0 || subtexture.offset[1] < 0) {
        fmt.printfln("Error while getting offset rect for subtexture: Out of bounds %s", loc)
        return { 0, 0, 0, 0 }
    }

    return {
        x = subtexture.is_relative ? parentAtlas.cell_size[0] * subtexture.offset[0] : subtexture.offset[0],
        y = subtexture.is_relative ? parentAtlas.cell_size[1] * subtexture.offset[1] : subtexture.offset[1],
        width = parentAtlas.cell_size[0],
        height = parentAtlas.cell_size[1]
    }
}