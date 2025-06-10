package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "core:encoding/json"

import types "../../libs/datatypes"

ItemID :: distinct u32

ItemDescriptor :: struct {
    name: cstring,
    sprite: Sprite
}

@(private)
ItemRegistry: types.Registry(ItemID, ItemDescriptor)
@(private)
ItemPathRegistry: types.Registry(string, ItemID)
@(private)
NextItemId: ItemID = 0

GetItemByID :: proc(
    id: ItemID
) -> ^ItemDescriptor {
    val, err := types.registry_get(&ItemRegistry, id)
    if err != nil do return nil

    return val
}

GetItemByPath :: proc(
    path: string,
) -> ^ItemDescriptor {
    id, err := GetItemIDByPath(path)
    if err != nil do return nil
    return GetItemByID(id^)
}

GetItemIDByPath :: proc(
    path: string
) -> (id: ^ItemID, err: types.Error) {
    return types.registry_get(&ItemPathRegistry, path)
}

LoadItem :: proc(
    path: string
) {
    fileData, err := os.read_entire_file(path)
    defer delete(fileData)
    
    jsonData, jErr := json.parse(fileData)
    defer json.destroy_value(jsonData)

    itemObject := jsonData.(json.Object)
    itemId := itemObject["id"].(json.String)
    itemName := itemObject["name"].(json.String)
    spriteObj := itemObject["sprite"].(json.Object)
    sprite := parse_sprite(spriteObj)

    newID, idErr := types.registry_put(&ItemPathRegistry, itemId, NextItemId)
    newItem, itemErr := types.registry_put(&ItemRegistry, NextItemId, ItemDescriptor{
        name = strings.clone_to_cstring(itemName),
        sprite = sprite
    })
    NextItemId += 1
}

UnloadItem :: proc(item: ^ItemDescriptor) {
    //Since we manually copy from String to CString we have to manually delete again at end of lifetime
    delete(item.name)
}