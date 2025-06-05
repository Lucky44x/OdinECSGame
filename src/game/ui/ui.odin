package ui

import "../../../libs/clay"
import "../../resource"
import "core:path/filepath"
import "core:fmt"
import "core:os"
import rl "vendor:raylib"

@(private) FONT_ID_BODY_16 :: 0
@(private) FONT_ID_BODY_24 :: 8
@(private) FONT_ID_BODY_28 :: 7
@(private) FONT_ID_BODY_30 :: 6
@(private) FONT_ID_BODY_36 :: 5

@(private) FONT_ID_TITLE_32 :: 4
@(private) FONT_ID_TITLE_36 :: 3
@(private) FONT_ID_TITLE_48 :: 2
@(private) FONT_ID_TITLE_52 :: 1
@(private) FONT_ID_TITLE_56 :: 9

@(private="file")
render_ui_layout :: proc() {

}

@(private="file")
render_debug_ui_layout :: proc() {

}

/**
Loads all required UI-Files
*/
load_ui_files :: proc() {
    fmt.printfln("PATH: %s", os.get_current_directory())

    resource.LoadFont(FONT_ID_TITLE_32, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_36, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_48, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_52, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_56, 32, "./assets/fonts/neue_regarde_semb.otf")

    resource.LoadFont(FONT_ID_BODY_16, 16, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_24, 24, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_28, 28, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_30, 30, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_36, 36, "./assets/fonts/neue_regarde_med.otf")
}

/**
Creates the UI Layout for the game
*/
create_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
    clay.BeginLayout()

    return clay.EndLayout()
}

/**
Draws the simple Debug Text info
*/
draw_debug_text :: proc(
    debug_mode: ^bool
) {
    rl.DrawTextEx(resource.GetFont(FONT_ID_TITLE_32), 
        "ODIN-DEBUG", 
        { 25, 25 }, 
        32, 5, rl.BLACK
    )

    rl.DrawTextEx(resource.GetFont(FONT_ID_BODY_24), 
        rl.TextFormat("DEBUG: %s", debug_mode^ ? "true" : "false"), 
        { 25, 55 }, 24, 5, rl.BLACK
    )

    rl.DrawTextEx(resource.GetFont(FONT_ID_BODY_24), 
        rl.TextFormat("FPS: %i", (i32)(1/rl.GetFrameTime())), 
        { 25, 80 }, 24, 5, rl.BLACK
    )
}