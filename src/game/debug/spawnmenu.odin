package debug

import "../world"
import rl "vendor:raylib"
import "core:fmt"

SpawnCommand :: struct {
    function: proc(x, y: f32),
    label: cstring
}

@(private="file")
SELECTION_COLOR: rl.Color = {200, 200, 200, 125} //Gray with a smaller opacity

@(private="file")
IS_ACTIVE: bool

@(private="file")
SELECTED_OPTION: int

@(private="file")
MENU_REC: rl.Rectangle
@(private="file")
SELECTED_REC: rl.Rectangle

@(private="file")
MENU_FONT_SIZE : f32 : 32
@(private="file")
MENU_MAX_WIDTH: f32 = 0

@(private="file")
COMMANDCOUNT: int = 0
@(private="file")
COMMANDS: [2]SpawnCommand

init_spawn_menu :: proc() {
    register_command("Spawn Enemy", spawn_enemy)

    //Add close "command" won't spawn anything but set ACTIVE to false
    register_command("Close", close_spawn_menu)

    //When done with registering commands figure out what the maximum width of our commands is
    for command in COMMANDS {
        commandWidth := f32(rl.MeasureText(command.label, i32(MENU_FONT_SIZE)))
        if commandWidth >= MENU_MAX_WIDTH do MENU_MAX_WIDTH = commandWidth
    }
}

draw_spawn_menu :: proc() {
    when !ODIN_DEBUG do return
    if !IS_ACTIVE do return

    //Draw marker
    rl.DrawCircleLines(i32(MENU_REC.x), i32(MENU_REC.y), 5, rl.RED)

    //Draw Menu
    rl.DrawRectangleRec(MENU_REC, rl.GRAY)

    //Text
    for command, ind in COMMANDS {
        rl.DrawText(
            command.label,
            i32(MENU_REC.x),
            i32(MENU_REC.y + ((MENU_FONT_SIZE + 5) * f32(ind))),
            i32(MENU_FONT_SIZE),
            rl.BLACK
        )
    }

    //Highlighted Section:
    SELECTED_REC.y = MENU_REC.y + f32(SELECTED_OPTION) * (MENU_FONT_SIZE + 5)
    rl.DrawRectangleRec(SELECTED_REC, SELECTION_COLOR)
}

update_spawn_menu :: proc() {
    when !ODIN_DEBUG do return
    
    //Check for open input
    if !IS_ACTIVE {
        if rl.IsMouseButtonPressed(rl.MouseButton.MIDDLE) do open_spawn_menu()
        return
    }

    //While active, check for mouse wheel delta and move selection index accordingly
    mouseWDelta := rl.GetMouseWheelMove()  

    if mouseWDelta <= -1 {
        //Move down
        SELECTED_OPTION += 1
        if SELECTED_OPTION >= COMMANDCOUNT do SELECTED_OPTION = COMMANDCOUNT - 1

    } else if mouseWDelta >= 1 {
        //Move up
        SELECTED_OPTION -= 1
        if SELECTED_OPTION <= 0 do SELECTED_OPTION = 0
    }

    //Check for confirm input
    if rl.IsMouseButtonPressed(rl.MouseButton.MIDDLE) do COMMANDS[SELECTED_OPTION].function(MENU_REC.x, MENU_REC.y)
}

@(private="file")
register_command :: proc(
    label: cstring,
    func: proc(x,y: f32)
) {
    COMMANDS[COMMANDCOUNT] = SpawnCommand{
        func,
        label
    }
    COMMANDCOUNT += 1
}

@(private="file")
open_spawn_menu :: proc() {
    IS_ACTIVE = true

    mousePos := rl.GetMousePosition()
    MENU_REC = rl.Rectangle{
        x = mousePos[0],
        y = mousePos[1],
        width = MENU_MAX_WIDTH + 32, //Max width + Padding
        height = f32(COMMANDCOUNT) * (MENU_FONT_SIZE + 5) //Line Height
    }

    SELECTED_OPTION = 0
    SELECTED_REC = rl.Rectangle{
        x = mousePos[0],
        y = mousePos[1],
        width = MENU_MAX_WIDTH + 32, //Max width + Padding
        height = (MENU_FONT_SIZE + 5) //Line Height
    }

    //fmt.printfln("psawning menu at %r", MENU_REC)
}

/*
                COMMANDS
*/
@(private="file")
close_spawn_menu :: proc(x, y: f32) {
    IS_ACTIVE = false
}

@(private="file")
spawn_enemy :: proc(x, y: f32) {
    //Just spawn an enemy
    world.enemy_spawn(rl.Vector2{x,y}, {25, 25}, 5, world.global_player_transform_ref)
    close_spawn_menu(x,y)
}