package main

import "game"
import "core:mem"
import "core:fmt"
import "resource"

tracking_alloc: mem.Tracking_Allocator

main :: proc() {
    //Initialize DEBUG components
    when ODIN_DEBUG {
        mem.tracking_allocator_init(&tracking_alloc, context.allocator)
        context.allocator = mem.tracking_allocator(&tracking_alloc)
    }

    //Initialize Registries and Data System
    resource.init_registries()

    //Start Game
    game.init_game_window(1280, 720, "Untitled Odin Game")
    
    /*
    Start Game Loop ---- BLOCKING
    CODE AFTER THIS CALL WILL NOT BE EXECUTED UNTIL GAME LOOP IS BROKEN
    */
    game.start_game_loop()

    //Deinitialize DEBUG components
    when ODIN_DEBUG {
        if len(tracking_alloc.bad_free_array) > 0 {
            fmt.printf("=== %v allocations badly freed: ===\n", len(tracking_alloc.bad_free_array))
            for entry in tracking_alloc.bad_free_array {
                fmt.printf("- %p @ %v\n", entry.memory, entry.location)
            }
        } else if len(tracking_alloc.allocation_map) > 0 {
            fmt.printf("=== %v allocations not freed: ===\n", len(tracking_alloc.allocation_map))
            for key, entry in tracking_alloc.allocation_map {
                fmt.printf("- %p @ %v\n", key, entry.location)
            }    
        }
        else do fmt.printf("=== NO BAD FREES FOUND ===\n")

        mem.tracking_allocator_destroy(&tracking_alloc)
    }

    //Close Window
    game.close_game_window()

    //Destroy registries
    resource.destroy_registries()

    //END OF PROGRAM
}