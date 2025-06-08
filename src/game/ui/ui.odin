package ui

import "../../../libs/clay"
import "../../resource"
import "core:path/filepath"
import "core:fmt"
import "core:os"
import rl "vendor:raylib"
import contextmenu "contextmenu/renderer"
import "fonts"

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
    fonts.load_fonts()
}

/**
Initializes the UI Systems
*/
init_ui :: proc() {
    contextmenu.init_context_menu()
}

/**
Deinitializes the UI Systems
*/
deinit_ui :: proc() {
    contextmenu.deinit_context_menu()
}

/**
Creates the UI Layout for the game
*/
create_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
    when ODIN_DEBUG do contextmenu.update_context_menu()
    
    clay.BeginLayout()

    when ODIN_DEBUG do contextmenu.context_menu_draw()

    return clay.EndLayout()
}

/**
Draws the simple Debug Text info
*/
draw_debug_text :: proc(
    debug_mode: ^bool
) {
    rl.DrawTextEx(resource.GetFont(fonts.FONT_ID_TITLE_32), 
        "ODIN-DEBUG", 
        { 25, 25 }, 
        32, 5, rl.BLACK
    )

    rl.DrawTextEx(resource.GetFont(fonts.FONT_ID_BODY_24), 
        rl.TextFormat("DEBUG: %s", debug_mode^ ? "true" : "false"), 
        { 25, 55 }, 24, 5, rl.BLACK
    )

    rl.DrawTextEx(resource.GetFont(fonts.FONT_ID_BODY_24), 
        rl.TextFormat("FPS: %i", (i32)(1/rl.GetFrameTime())), 
        { 25, 80 }, 24, 5, rl.BLACK
    )
}