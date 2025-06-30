package window

import "core:container/intrusive/list"
import "../../../../libs/clay"
import "../fonts"
import rl "vendor:raylib"
import "core:fmt"

Windows: [dynamic]UiWindow

UiWindow :: struct {
    title: string,
    windowid: u32,
    offset, grabOffset: clay.Vector2,
    params: rawptr,
    constructor: proc(rawptr),
    isOpen, isDragging: bool
}

WindowTitleStyle: clay.TextElementConfig = {
    fontId = fonts.FONT_ID_BODY_16,
    fontSize = 16,
    textColor = clay.Color({ 200, 200, 200, 255 }),
    textAlignment = clay.TextAlignment.Left
}

WindowButtonStyle: clay.TextElementConfig = {
    fontId = fonts.FONT_ID_BODY_16,
    fontSize = 16,
    textColor = clay.Color{ 200, 200, 200, 255 },
    textAlignment = clay.TextAlignment.Center
}

GetWindowParams :: proc($T: typeid, self: rawptr) -> T { return cast(T)self }

AddWindow :: proc(
    window: UiWindow,
) {
    append(&Windows, window)
    ptr := &Windows[len(&Windows) - 1]

    ptr.windowid = auto_cast len(Windows)
    ptr.isOpen = true
}

CleanWindows :: proc() {
    index := 0

    for true {
        if index >= len(Windows) do break
        if Windows[index].isOpen {
            //If open, skip this entry and increment
            index += 1
            continue
        }

        //If not open, remove at this index, but do not increment index
        ordered_remove(&Windows, index)
    }
}

init_windows :: proc() {
    Windows = make([dynamic]UiWindow)
}

draw_windows :: proc() {
    for &window in Windows do draw_window(&window)

}

update_windows :: proc() {
    CleanWindows()
}

draw_window :: proc(window: ^UiWindow) {
    if clay.UI()({
        id = clay.ID("window-frame", window.windowid),
        layout = {
            sizing = { width = clay.SizingFit({ 75, 1024 }), height = clay.SizingFit({}) },
            padding = { 0, 0, 0, 0 },
            childGap = 8,
            layoutDirection = clay.LayoutDirection.TopToBottom
        },
        floating = {
            offset = window.offset,
            expand = {},
            attachment = {
                element = clay.FloatingAttachPointType.LeftTop,
                parent = clay.FloatingAttachPointType.LeftTop
            },
            zIndex = 10,
            attachTo = clay.FloatingAttachToElement.Root,
            clipTo = clay.FloatingClipToElement.None,
            pointerCaptureMode = clay.PointerCaptureMode.Capture
        },
        backgroundColor = clay.Color({ 80, 80, 80, 255 }),
        cornerRadius = { 15, 15, 15, 15 },
    }) {
        
        //Render Header
        if clay.UI()({
            id = clay.ID("window-header", window.windowid),
            layout = {
                sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                padding = { 8, 8, 8, 8 },
                childGap = 8,
                childAlignment = clay.ChildAlignment{
                    x = clay.LayoutAlignmentX.Left,
                    y = clay.LayoutAlignmentY.Center
                },
                layoutDirection = clay.LayoutDirection.LeftToRight
            },
            backgroundColor = clay.Color({ 65, 65, 65, 255 }),
            cornerRadius = { 15, 15, 0, 0 },
        }) {
            if clay.Hovered() && rl.IsMouseButtonPressed(.LEFT) {
                window.isDragging = true
                window.grabOffset = window.offset - rl.GetMousePosition()
            }

            if window.isDragging {
                window.offset = rl.GetMousePosition() + window.grabOffset
                
                if rl.IsMouseButtonReleased(.LEFT) do window.isDragging = false
            }

            //Title
            clay.TextDynamic(window.title, &WindowTitleStyle)

            if clay.UI()({
                id = clay.ID("window-header-spacer", window.windowid),
                layout = {
                    sizing = { width = clay.SizingFixed(25), height = clay.SizingFixed(15) }
                }
            }) {}

            //Close Button
            if clay.UI()({
                id = clay.ID("window-button", window.windowid),
                layout = {
                    sizing = { width = clay.SizingFit({ 15, 15 }), height = clay.SizingGrow({ 15, 0 }) },
                    padding = { 8, 8, 8, 8 },
                    childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center }
                },
            }) {
                backCol := clay.Color{ 80, 80, 80, 255 }
                if clay.Hovered() do backCol = clay.Color{ 255, 0, 0, 255 }
                
                if clay.UI()({
                    id = clay.ID("window-button-inner", window.windowid),
                    layout = {
                        sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                        padding = { 8, 8, 8, 8 },
                        childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center },
                    },
                    backgroundColor = backCol
                }) {
                    //TODO: Fix Later - Font ID gets mutated for some reason

                    if clay.Hovered() && rl.IsMouseButtonPressed(.LEFT) {
                        window.isOpen = false
                    }

                    clay.Text("X", &WindowButtonStyle)
                }
            }
        }

        //Render Contents
        window.constructor(window.params)
    }

    window.constructor(window.params)
}