package window

import "core:container/intrusive/list"
import "../../../../libs/clay"
import "../fonts"

Windows: [dynamic]UiWindow

UiWindow :: struct {
    title: string,
    offset: clay.Vector2,
    params: rawptr,
    constructor: proc(rawptr),
    isOpen: bool
}

GetWindowParams :: proc($T: typeid, self: rawptr) -> T { return cast(T)self }

AddWindow :: proc(
    window: UiWindow,
) {
    append(&Windows, window)
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

}

draw_window :: proc(window: ^UiWindow) {
    if clay.UI()({
        id = clay.ID(window.title),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = { 8, 8, 8, 8 },
            childGap = 8,
            layoutDirection = clay.LayoutDirection.TopToBottom
        },
        cornerRadius = { 5, 5, 5, 5 },
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
        backgroundColor = clay.Color({ 80, 80, 80, 255 })
    }) {
        
        //Render Header
        if clay.UI()({
            id = clay.ID(window.title, 1),
            layout = {
                sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                padding = { 8, 8, 8, 8 },
                childGap = 8,
                layoutDirection = clay.LayoutDirection.LeftToRight
            },
            backgroundColor = clay.Color({ 65, 65, 65, 255 })
        }) {
            //Title
            clay.TextDynamic(window.title, &clay.TextElementConfig{
                fontId = fonts.FONT_ID_TITLE_32,
                fontSize = 32,
                textColor = clay.Color({ 200, 200, 200, 255 }),
                textAlignment = clay.TextAlignment.Left
            })

            //Close Button
            if clay.UI()({
                id = clay.ID(window.title, 2),
                layout = {
                    sizing = { width = clay.SizingFit({}), height = clay.SizingGrow({}) },
                    padding = { 8, 8, 8, 8 },
                    childAlignment = { x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center }
                },
                backgroundColor = clay.Color({ 80, 80, 80, 255 })
            }) {

            }
        }
    }

    window.constructor(window.params)
}