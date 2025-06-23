package game

import clay "../../libs/clay"
import "../../libs/jobs"

import rl "vendor:raylib"
import "world"
import clayrl "../clay_render"
import "core:fmt"
import "ui"
import "../input"
import "profiling"
import "core:time"

import "../resource"

@(private="file")
clay_minMemorySize: uint
@(private="file")
clay_memory: [^]u8
@(private="file")
clay_arena: clay.Arena
@(private="file")
clay_debug_mode: bool

/*
Initializes the Game Window with the provided with and height using Raylib
*/
init_game_window :: proc(
    width: i32,
    height: i32,
    title: cstring
) {
    //Initialize Clay Renderer
    clay_minMemorySize = cast(uint)clay.MinMemorySize()
    clay_memory = make([^]u8, clay_minMemorySize) //Crazy way to allocate a certain amount of bytes, but hey, if it works it works
    clay_arena = clay.CreateArenaWithCapacityAndMemory(clay_minMemorySize, clay_memory)
    clay.Initialize(clay_arena, {cast(f32)width, cast(f32)height}, { handler = clay_errorHandler})
    clay.SetMeasureTextFunction(clayrl.measure_text, nil)

    clay_debug_mode = ODIN_DEBUG
    clay.SetDebugModeEnabled(clay_debug_mode)

    //Init Game Window
    rl.SetConfigFlags({ .VSYNC_HINT, .MSAA_4X_HINT })
    rl.InitWindow(width, height, title)
    rl.SetExitKey(.KEY_NULL)

    rl.SetTargetFPS(60)

    //TODO: Recap to refresh  rate -- Vsync ... For debug purposes always capped to 60
    //rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))

    //Load UI Files
    ui.load_ui_files()
    ui.init_ui()

    //Init Input Maps
    init_input_mappings()

    //Initialize JOB system
    jobs.initialize(
        //num_worker_threads = 4,
        thread_proc = proc(_: rawptr) {
            for jobs.is_running() {
                if !jobs.try_execute_queued_job() {
                    time.sleep(2 * time.Millisecond)
                }
            }
        })

    profiling._profiler_init()

    resource.reload_data()

    world.init_world()
}

clay_errorHandler :: proc "c" (errorData: clay.ErrorData) {
    //libc.fprintf(libc.stderr, "Error of type: %e in clay  UI -> %s", errorData.errorType, errorData.errorText)
}

/*
Deinitializes the Game Window and it's corresponding World, entities and components
*/
deinit_game_window :: proc() {
    world.deinit_world()
    
    ui.deinit_ui()

    jobs.shutdown()

    profiling._profiler_shutdown()

    free(clay_memory)

    resource.UnloadFonts()
}

/*
Will Execute the game-loop

CUATION WILL ACT BLOCKING UNTIL GAME-LOOP IS BROKEN
*/
start_game_loop :: proc() {
    for !rl.WindowShouldClose() {
        profiling.profile_begin("GameLoop")

        //Resolve our Inputs
        profiling.profile_begin("Input Resolving")
        resolvedMap := input.resolve_input_map(&InputMap_World)
        profiling.profile_end()

        profiling.profile_begin("UI - Update")

        //Get Clay ready for drawing
        clay.SetPointerState(transmute(clay.Vector2)rl.GetMousePosition(), rl.IsMouseButtonDown(.LEFT))
        clay.UpdateScrollContainers(false, transmute(clay.Vector2)rl.GetMouseWheelMoveV(), rl.GetFrameTime())
        clay.SetLayoutDimensions({ cast(f32)rl.GetRenderWidth(), cast(f32)rl.GetRenderHeight() })
        clay_rendercommands: clay.ClayArray(clay.RenderCommand) = ui.create_layout(resolvedMap)

        //Do Update specific Debug logic
        when ODIN_DEBUG {
            if rl.IsKeyPressed(.M) {
                clay_debug_mode = !clay_debug_mode
                clay.SetDebugModeEnabled(clay_debug_mode)
            }
        }

        profiling.profile_end()

        //Do Logic
        world.run_update_systems(&resolvedMap)

        profiling.profile_begin("Game - Drawing")

        //Do Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        
        world.run_drawing_systems()

        profiling.profile_begin("UI - Drawing")

        //Render Clay (UI) on top of world elements
        clayrl.clay_raylib_render(&clay_rendercommands)
        
        profiling.profile_end()

        when ODIN_DEBUG {
            ui.draw_debug_text(&clay_debug_mode)
        }

        //Do State specific drawing
        rl.EndDrawing()
        profiling.profile_end()
        profiling.profile_end()

        free_all(context.temp_allocator)
    }
}

/*
Will close the window previously opened by "init_game_window(w,h,t)"
*/
close_game_window :: proc() {
    rl.CloseWindow()
}