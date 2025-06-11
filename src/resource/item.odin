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

ItemStack :: struct {
    id: ItemID,
    count: i32
}

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

InsertItem :: proc(
    id: string,
    item: ItemDescriptor
) {
    newID, idErr := types.registry_put(&ItemPathRegistry, id, NextItemId)
    newItem, itemErr := types.registry_put(&ItemRegistry, NextItemId, item)
    NextItemId += 1    
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

    InsertItem(itemId, ItemDescriptor{
        name = strings.clone_to_cstring(itemName),
        sprite = sprite
    })
}

UnloadItem :: proc(item: ^ItemDescriptor) {
    //Since we manually copy from String to CString we have to manually delete again at end of lifetime
    delete(item.name)
}