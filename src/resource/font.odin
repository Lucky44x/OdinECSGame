package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"
import clayrl "../clay_render"
import types "../../libs/datatypes"

GetFont :: proc(
    fontId: u16
) -> rl.Font {
    return clayrl.raylib_fonts[fontId].font
}

LoadFont :: proc(
    fontId, fontSize: u16,
    path: cstring
) {
    fmt.printfln("loading %s", path)
    assign_at(&clayrl.raylib_fonts, fontId, clayrl.Raylib_Font{
        font = rl.LoadFontEx(path, i32(fontSize) * 2, nil, 0),
        fontId = u16(fontId)
    })
    rl.GenTextureMipmaps(&clayrl.raylib_fonts[fontId].font.texture)
    rl.SetTextureFilter(clayrl.raylib_fonts[fontId].font.texture, rl.TextureFilter.TRILINEAR)
}


//TODO Add Unloading