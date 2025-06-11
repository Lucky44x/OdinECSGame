package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import "core:os"
import "base:runtime"
import "core:encoding/json"

import types "../../libs/datatypes"

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
    types.registry_init(&ItemRegistry, UnloadItem)
    types.registry_init(&RecipeRegistry, UnloadRecipe)
    types.registry_init(&ItemPathRegistry, proc(^ItemID){})
    types.registry_init(&RecipePathRegistry, proc(^RecipeID){})
    types.registry_init(&TexturePathRegistry, proc(^cstring){})

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
}

/*
Destroys all Registires and their contents inside the Data System
*/
destroy_registries :: proc() {
    types.registry_destroy(&AnimationRegistry)
    types.registry_destroy(&TextureRegistry)
    types.registry_destroy(&ItemRegistry)
    types.registry_destroy(&RecipeRegistry)
    types.registry_destroy(&ItemPathRegistry)
    types.registry_destroy(&RecipePathRegistry)
    types.registry_destroy(&TexturePathRegistry)
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
    dstRec := rl.Rectangle {
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