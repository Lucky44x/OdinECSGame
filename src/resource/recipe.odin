package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "core:encoding/json"

import types "../../libs/datatypes"

RecipeID :: distinct u32

RecipeDescriptor :: struct {
    name: cstring,
    prodRatePerMin, prodRatePerTick: f32,
    inputs: []ItemStack,
    outputs: []ItemStack
}

@(private)
RecipeRegistry: types.Registry(RecipeID, RecipeDescriptor)
@(private)
RecipePathRegistry: types.Registry(string, RecipeID)
@(private)
NextRecipeId: RecipeID = 0

GetRecipeByID :: proc(
    id: RecipeID
) -> ^RecipeDescriptor {
    val, err := types.registry_get(&RecipeRegistry, id)
    if err != nil do return nil

    return val
}

GetRecipeByPath :: proc(
    path: string,
) -> ^RecipeDescriptor {
    id, err := GetRecipeIDByPath(path)
    if err != nil do return nil
    return GetRecipeByID(id^)
}

GetRecipeIDByPath :: proc(
    path: string
) -> (id: ^RecipeID, err: types.Error) {
    return types.registry_get(&RecipePathRegistry, path)
}

InsertRecipe :: proc(
    id: string,
    recipe: RecipeDescriptor
) {
    newID, idErr := types.registry_put(&RecipePathRegistry, id, NextRecipeId)
    newRecipe, itemErr := types.registry_put(&RecipeRegistry, NextRecipeId, recipe)
    NextItemId += 1

    //Do tickrate calculations - item/min divided by 60 -> item/sec divided by 10 (ticks per sec) -> item/tick
    newRecipe.prodRatePerTick = (newRecipe.prodRatePerMin / 60) / 10
}

UnloadRecipe :: proc(recipe: ^RecipeDescriptor) {
    //Since we manually copy from String to CString we have to manually delete again at end of lifetime
    delete(recipe.name)
}