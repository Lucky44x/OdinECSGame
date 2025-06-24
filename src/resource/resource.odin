package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "base:runtime"
import "core:encoding/json"
import "core:time"

import "core:sync"

import types "../../libs/datatypes"

FILES_TO_LOAD: u32
LOADED_FILES: u32

//Common DataTypes
Sprite :: struct {
    scaling, origin: rl.Vector2,
    color: rl.Color,
    source: Renderable
}

Renderable :: union {
    ^rl.Texture2D,
    SubImage,
    PrimitiveEllipse,
    PrimitiveRect
}

SubImage :: struct {
    tex: ^rl.Texture2D,
    srcRec: rl.Rectangle
}

PrimitiveRect :: struct {}
PrimitiveEllipse :: struct {}

//Common Functions

/*
Initializes the Resource Systems and it's Registries
*/
init_registries :: proc() {
    types.registry_init(&AnimationRegistry, UnloadAnimation)
    types.registry_init(&TextureRegistry, UnloadTexture)
    types.registry_init(&TexturePathRegistry, proc(^cstring){})

    make_data_registries()

    //Insert the default Item (0)
    InsertItem("item_null", ItemDescriptor{
        name = strings.clone_to_cstring("NULL"),
        sprite = Sprite{
            scaling = { 15, 15 },
            origin = { 0.5, 0.5 },
            color = rl.PINK,
            source = PrimitiveRect{}
        }
    })

    InsertRecipe("recipe_null", RecipeDescriptor{
        name = strings.clone_to_cstring("NULL"),
        inputs = nil,
        outputs = nil,
        prodRatePerMin = 0
    })

    building := InsertBuilding("building_null", BuildingDescriptor{
        name = strings.clone_to_cstring("NULL"),
        sprite = Sprite{
            scaling = { 100, 75 },
            origin = { 0.5, 0.5 },
            color = rl.PINK,
            source = PrimitiveRect{}
        },
        inputs = make([]rl.Vector3, 1),
        outputs = make([]rl.Vector3, 1),
        recipes = make([]RecipeID, 1)
    })
    building.inputs[0] = { 0, -0.5, 180 }
    building.outputs[0] = { 0, 0.5, 0 }
}

make_data_registries :: proc() {
    types.registry_init(&ItemRegistry, UnloadItem)
    types.registry_init(&RecipeRegistry, UnloadRecipe)
    types.registry_init(&BuildingRegistry, UnloadBuilding)
    types.registry_init(&ItemPathRegistry, proc(^ItemID){})
    types.registry_init(&RecipePathRegistry, proc(^RecipeID){})
    types.registry_init(&BuildingPathRegistry, proc(^BuildingID){})
}

/*
Destroys all Registires and their contents inside the Data System
*/
destroy_registries :: proc() {
    types.registry_destroy(&AnimationRegistry)
    types.registry_destroy(&TextureRegistry)
    types.registry_destroy(&TexturePathRegistry)
    destroy_data_registies()
}

destroy_data_registies :: proc() {
    types.registry_destroy(&ItemRegistry)
    types.registry_destroy(&RecipeRegistry)
    types.registry_destroy(&BuildingRegistry)
    types.registry_destroy(&ItemPathRegistry)
    types.registry_destroy(&RecipePathRegistry)
    types.registry_destroy(&BuildingPathRegistry)
}

count_data :: proc(
    dir: string
) -> int {
    pattern := filepath.join({dir, "*.json"}, context.temp_allocator)
    found, err := filepath.glob(pattern, context.temp_allocator)
    return len(found)
}

reload_data :: proc() {
    //Count all files
    FILES_TO_LOAD = 0
    FILES_TO_LOAD += u32(count_data("./assets/items"))
    FILES_TO_LOAD += u32(count_data("./assets/recipes"))
    FILES_TO_LOAD += u32(count_data("./assets/machines"))

    //Reset registries
    destroy_data_registies()
    make_data_registries()

    LoadAllItems("./assets/items")
    time.sleep(5 * time.Millisecond)

    LoadAllRecipes("./assets/recipes")
    time.sleep(5 * time.Millisecond)
    
    LoadAllBuildings("./assets/machines")
    time.sleep(5 * time.Millisecond)

    free_all(context.temp_allocator)
}

/*
Parses a ItemStack from a json Object
*/
parse_item_stack :: proc(
    obj: json.Object
) -> ItemStack {
    //TODO: Add fluids later on
    itemPath := obj["item"].(json.String)
    itemCount := obj["count"].(json.Float)

    itemID, err := GetItemIDByPath(itemPath)
    if err != nil {
        fmt.eprintfln("Could not load Item: %s... %e", itemPath, err)
        //panic("err during stack parsing")
    }
    if itemID^ == 0 {
        fmt.eprintfln("Warning: Item %s in parsing is bound to idx 0 meaning it is a null-item")
        //panic("err during stack parsing")
    }

    return ItemStack{
        id = itemID^,
        count = i32(itemCount)
    }
}

/*
Parses a Renderable from a JSON Object.
Used to dynamically generate Rendering representations for Items, Buildings etc.
*/
parse_sprite :: proc(
    obj: json.Object
) -> Sprite {
    type := obj["src"].(json.String)

    //Source is a primitive shape
    colorObj := obj["color"].(json.Object)
    r,g,b,a: u8 = 0, 0, 0, 255

    r = u8(colorObj["r"].(json.Float))
    g = u8(colorObj["g"].(json.Float))
    b = u8(colorObj["b"].(json.Float))
    if colorObj["a"] != nil do a = u8(colorObj["a"].(json.Float))
    color: rl.Color = {r, g, b, a}
    
    scalingArr := obj["scaling"].(json.Array)
    scalingX := scalingArr[0].(json.Float)
    scalingY := scalingArr[1].(json.Float)
    scaling := rl.Vector2{ f32(scalingX), f32(scalingY) }

    originArr := obj["origin"].(json.Array)
    originX := originArr[0].(json.Float)
    originY := originArr[1].(json.Float)
    origin := rl.Vector2{ f32(originX), f32(originY) }

    finalSprite: Sprite = {
        color = color,
        origin = origin,
        scaling = scaling
    }

    if strings.starts_with(type, "primitive") {
        if strings.contains(type, "rectangle") do finalSprite.source = PrimitiveRect{}
        else if strings.contains(type, "ellipse") do finalSprite.source = PrimitiveEllipse{}
    }
    else if strings.starts_with(type, "subimage") {
        finalSprite.source = SubImage{
            //TODO: Implement SubImage as source
        }
    }
    else {
        //If not primive or subimage, assume it's a texture
        finalSprite.source = GetTextureByID(type)
    }

    return finalSprite
}

render_sprite :: proc(
    sprite: ^Sprite,
    pos: rl.Vector2,
    rotation: f32
) {
    if sprite == nil do return
    
    dstRec := rl.Rectangle {    //Null pointer ??????? TODO: Fix
        x = pos[0],
        y = pos[1],
        width = sprite.scaling[0],
        height = sprite.scaling[1]
    }

    origin_px := sprite.origin * sprite.scaling

    #partial switch type in sprite.source {
        case PrimitiveEllipse:
            rl.DrawEllipse(i32(dstRec.x), i32(dstRec.y), dstRec.width, dstRec.height, sprite.color)
            break
        case PrimitiveRect:
            rl.DrawRectanglePro(dstRec, origin_px, rotation, sprite.color)
            break
    }
}