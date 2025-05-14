package game

import rl "vendor:raylib"
import "world"
import "debug"

/*
Initializes the Game Window with the provided with and height using Raylib
*/
init_game_window :: proc(
    width: i32,
    height: i32,
    title: cstring
) {
    rl.InitWindow(width, height, title)
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(60)

    when ODIN_DEBUG do debug.init_spawn_menu()

    //world.init_world()
}

/*
Will start the actual game-loop

CAUTION: WILL ACT AS A BLCOKING WHILE LOOP !!
AS LONG AS THE GAME RUNS NOTHING AFTER THIS LINE WILL BE RUN
*/
start_game_loop :: proc() {
    //rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {

        //Spawn menu
        when ODIN_DEBUG do debug.update_spawn_menu()

        //Do Logic
        //world.do_logic_systems()

        //Do Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        
        //world.do_drawing_systems()

        when ODIN_DEBUG {
            //Spawn Menu
            debug.draw_spawn_menu()

            rl.DrawText("DEBUG", 25, 25, 25, rl.BLACK)
            rl.DrawText(rl.TextFormat("FPS: %i", (i32)(1/rl.GetFrameTime())), 25, 50, 25, rl.BLACK)
        }

        //Do State specific drawing

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    //world.deinit_world()
}

/*
Will close the window previously opened by "init_game_window(w,h,t)"
*/
close_game_window :: proc() {
    rl.CloseWindow()
}