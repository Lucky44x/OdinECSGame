package resource

import "core:text/edit"
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
    TextureID,
    PrimitiveEllipse,
    PrimitiveRect
}

PrimitiveRect :: struct {}
PrimitiveEllipse :: struct {}

//Common Functions

/*
Initializes the Resource Systems and it's Registries
*/
init_registries :: proc() {
    //types.registry_init(&AnimationRegistry, UnloadAnimation)

    make_data_registries()

    //Insert the default Texture (0)
    InsertTexture("tex_null", nil)

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
    types.registry_init(&TextureRegistry, proc(_: ^Texture){})
    types.registry_init(&ItemRegistry, UnloadItem)
    types.registry_init(&RecipeRegistry, UnloadRecipe)
    types.registry_init(&BuildingRegistry, UnloadBuilding)
    types.registry_init(&TexturePathRegistry, proc(^TextureID){})
    types.registry_init(&ItemPathRegistry, proc(^ItemID){})
    types.registry_init(&RecipePathRegistry, proc(^RecipeID){})
    types.registry_init(&BuildingPathRegistry, proc(^BuildingID){})
}

/*
Destroys all Registires and their contents inside the Data System
*/
destroy_registries :: proc() {
    //types.registry_destroy(&AnimationRegistry)
    destroy_data_registies()
}

destroy_data_registies :: proc() {
    types.registry_destroy(&TextureRegistry)
    types.registry_destroy(&ItemRegistry)
    types.registry_destroy(&RecipeRegistry)
    types.registry_destroy(&BuildingRegistry)
    types.registry_destroy(&TexturePathRegistry)
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
    FILES_TO_LOAD += u32(count_data("./assets/textures"))
    FILES_TO_LOAD += u32(count_data("./assets/items"))
    FILES_TO_LOAD += u32(count_data("./assets/recipes"))
    FILES_TO_LOAD += u32(count_data("./assets/machines"))

    //Reset registries
    destroy_data_registies()
    make_data_registries()

    //Load atlases first, then load general textures
    LoadAllTextures("./assets/textures", "_atlas")
    LoadAllTextures("./assets/textures", "_tex")

    LoadAllItems("./assets/items")
    //time.sleep(5 * time.Millisecond)

    fmt.printfln("Loaded Items: paths: %s\n --- \n items: %s", ItemPathRegistry, ItemRegistry)

    LoadAllRecipes("./assets/recipes")
    //time.sleep(5 * time.Millisecond)
    
    LoadAllBuildings("./assets/machines")
    //time.sleep(5 * time.Millisecond)

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
        fmt.eprintfln("Could not load Item: %s... %e, %s", itemPath, err, ItemPathRegistry)
    }

    assert(itemID != nil, fmt.aprintfln("Could not load Item %s", ItemRegistry))

    if itemID == nil || itemID^ == 0 {
        fmt.eprintfln("Warning: Item %s in parsing is bound to idx 0 meaning it is a null-item")
        panic("err during stack parsing")
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
    obj: json.Object,
    loc := #caller_location
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
    else {
        //Assume it's a texture and try to get ID
        id, err := GetTextureIDByPath(type)
        assert(id != nil, fmt.tprintfln("Could not find texture %s \n %s", type, loc))
        finalSprite.source = id^
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
        case TextureID:
            draw_texture(type, dstRec, origin_px, rotation, sprite.color)
            break
    }
}

draw_texture :: proc(
    id: TextureID, 
    destination: rl.Rectangle, 
    origin: rl.Vector2, 
    rotation: f32, 
    tint: rl.Color,
    loc := #caller_location
) {
    texture := GetTextureByID(id)
    assert(texture != nil, "texture could not be read", loc)

    tex: rl.Texture2D 
    srcRec: rl.Rectangle
    #partial switch &type in texture {
        case rl.Texture2D:
            srcRec = get_src_rec(&type)
            tex = type
            break
        case SubTexture:
            srcRec = get_src_rec(&type)
            source := GetTextureByID(type.src)
            
            #partial switch &texType in source {
                case TextureAtlas:
                    break
                case rl.Texture2D:
                    fmt.printfln("Source of subtexture %i with id %i was not of type atlas but of type Texture2D", id, type.src)
                    return
                case SubTexture:
                    fmt.printfln("Source of subtexture %i with id %i was not of type atlas but of type SubTexture", id, type.src)
                    return
            }

            //assert(, "Source Texture was not an atlas", loc)
            temp := source.(TextureAtlas)
            tex = temp.src
            break
    }

    rl.DrawTexturePro(tex, srcRec, destination, origin, rotation, tint)
}