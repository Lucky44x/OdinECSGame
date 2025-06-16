package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "core:encoding/json"

import types "../../libs/datatypes"

BuildingID :: distinct u32

BuildingDescriptor :: struct {
    name: cstring,
    sprite: Sprite,
    inputs: []rl.Vector3,
    outputs: []rl.Vector3,
    recipes: []RecipeID
}

@(private)
BuildingRegistry: types.Registry(BuildingID, BuildingDescriptor)
@(private)
BuildingPathRegistry: types.Registry(string, BuildingID)
@(private)
NextBuildingId: BuildingID = 0

GetBuildingByID :: proc(
    id: BuildingID
) -> ^BuildingDescriptor {
    val, err := types.registry_get(&BuildingRegistry, id)
    if err != nil do return nil

    return val
}

GetBuildingByPath :: proc(
    path: string,
) -> ^BuildingDescriptor {
    id, err := GetBuildingIDByPath(path)
    if err != nil do return nil
    return GetBuildingByID(id^)
}

GetBuildingIDByPath :: proc(
    path: string
) -> (id: ^BuildingID, err: types.Error) {
    return types.registry_get(&BuildingPathRegistry, path)
}

InsertBuilding :: proc(
    id: string,
    building: BuildingDescriptor
) -> ^BuildingDescriptor {
    newID, idErr := types.registry_put(&BuildingPathRegistry, id, NextBuildingId)
    newItem, itemErr := types.registry_put(&BuildingRegistry, NextBuildingId, building)
    NextBuildingId += 1
    return newItem
}

LoadBuilding :: proc(
    path: string
) {
    fileData, err := os.read_entire_file(path)
    defer delete(fileData)
    
    jsonData, jErr := json.parse(fileData)
    defer json.destroy_value(jsonData)

    buildingObject := jsonData.(json.Object)
    buildingID := buildingObject["id"].(json.String)
    buildingName := buildingObject["name"].(json.String)
    buildingRenderable := buildingObject["renderable"].(json.Object)
    buildingSprite := parse_sprite(buildingRenderable)
    buildingInputArray := buildingObject["inputs"].(json.Array)
    
    buildingInputs := make([]rl.Vector3, len(buildingInputArray))
    for i := 0; i < len(buildingInputArray); i += 1 {
        vecArray := buildingInputArray[i].(json.Array)
        buildingInputs[i] = rl.Vector3{ f32(vecArray[0].(json.Float)), f32(vecArray[1].(json.Float)), f32(vecArray[2].(json.Float)) }
    }
    
    buildingOutputArray := buildingObject["outputs"].(json.Array)
    buildingOutputs := make([]rl.Vector3, len(buildingOutputArray))
    for i := 0; i < len(buildingOutputArray); i += 1 {
        vecArray := buildingOutputArray[i].(json.Array)
        buildingOutputs[i] = rl.Vector3{ f32(vecArray[0].(json.Float)), f32(vecArray[1].(json.Float)), f32(vecArray[2].(json.Float)) }
    }

    buildingRecipeArray := buildingObject["recipes"].(json.Array)
    buildingRecipes := make([]RecipeID, len(buildingRecipeArray))
    for i := 0; i < len(buildingRecipeArray); i += 1 {
        val, err := GetRecipeIDByPath(buildingRecipeArray[i].(json.String))
        if err != nil do buildingRecipes[i] = 0
        else do buildingRecipes[i] = val^
    }

    InsertBuilding(buildingID, BuildingDescriptor{
        name = strings.clone_to_cstring(buildingName),
        sprite = buildingSprite,
        inputs = buildingInputs,
        outputs = buildingOutputs,
        recipes = buildingRecipes
    })
}

UnloadBuilding :: proc(building: ^BuildingDescriptor) {
    //Since we manually copy from String to CString we have to manually delete again at end of lifetime
    delete(building.name)
    delete(building.inputs)
    delete(building.outputs)
    delete(building.recipes)
}