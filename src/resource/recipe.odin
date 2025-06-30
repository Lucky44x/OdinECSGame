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
    NextRecipeId += 1

    assert(itemErr == nil, "Error during recipe insertion")

    //Do tickrate calculations - item/min divided by 60 -> item/sec divided by 10 (ticks per sec) -> item/tick
    newRecipe.prodRatePerTick = (newRecipe.prodRatePerMin / 60) / 10
}

LoadAllRecipes :: proc(
    dir: string
) {
    pattern := filepath.join({dir, "*.json"}, context.temp_allocator)
    found, err := filepath.glob(pattern, context.temp_allocator)
    for path in found do LoadRecipe(path)
}

LoadRecipe :: proc(
    path: string
) {
    fileData, err := os.read_entire_file(path)
    defer delete(fileData)
    
    jsonData, jErr := json.parse(fileData)
    defer json.destroy_value(jsonData)

    recipeObject := jsonData.(json.Object)
    recipeID := recipeObject["id"].(json.String)
    recipeName := recipeObject["name"].(json.String)
    productionRate := recipeObject["rate"].(json.Float)

    inputArr := recipeObject["inputs"].(json.Array)
    recipeInputs := make([]ItemStack, len(inputArr))
    for type, ind in inputArr {
        recipeInputs[ind] = parse_item_stack(type.(json.Object))
    }

    outputArr := recipeObject["outputs"].(json.Array)
    recipeOutputs := make([]ItemStack, len(outputArr))
    for type, ind in outputArr {
        recipeOutputs[ind] = parse_item_stack(type.(json.Object)) 
    }

    InsertRecipe(strings.clone(recipeID), RecipeDescriptor{
        name = strings.clone_to_cstring(recipeName),
        prodRatePerMin = f32(productionRate),
        prodRatePerTick = 0,
        inputs = recipeInputs,
        outputs = recipeOutputs
    })

    when ODIN_DEBUG {
        newID, err2 := GetRecipeIDByPath(recipeID)
        fmt.printfln("Loaded Recipe \"%s\" as \"%s\" with numeric id %i", recipeName, recipeID, newID^)
        fmt.printfln("Recipe-Data: %s", GetRecipeByID(newID^)^)
    }
    LOADED_FILES += 1
}

UnloadRecipe :: proc(recipe: ^RecipeDescriptor) {
    //Since we manually copy from String to CString we have to manually delete again at end of lifetime
    delete(recipe.name)
    delete(recipe.inputs)
    delete(recipe.outputs)
}