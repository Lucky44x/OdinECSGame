package resource

import rl "vendor:raylib"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:mem"

@(private)
AnimationRegistry: Registry(AnimationClip)

AnimationClip :: struct {
    frameTime, frameCount: i32,
    frames: []Renderable
}

/*
Will load either a Frame-Animation or a SheetAnimation depending on arguments
*/
LoadAnimation :: proc {
    LoadFrameAnimation,
    LoadSheetAnimation,
}

/*
Returns the requested Animation reference, or nil, if none was found
*/
GetAnimation :: proc(animationID: cstring) -> ^AnimationClip {
    ref, _ := registry_get(&AnimationRegistry, animationID)
    return ref
}

/*
Will Load an Animation by getting each frame from its own file 
and loads the animation into the registry under the provided name

the file-names and directory should look like this

[directoryPath]   
-> [fileName]0.[fileType]   
-> [fileName]1.[fileType]   
-> [fileName]2.[fileType]   
...
*/
@(private="file")
LoadFrameAnimation :: proc (
    animationName: cstring,
    directoryPath, fileType, fileName: string,
    frameCount, frameTime: i32
) -> ^AnimationClip {
    //First check if we are trying to add an already existing element
    alreadyLoaded, _ := registry_has(&AnimationRegistry, animationName)
    //If so, return its reference
    if alreadyLoaded {
        ref, _ := registry_get(&AnimationRegistry, animationName)
        return ref
    }

    //Else, load the element from disk
    newAnimation := animation_clip_create(frameTime, frameCount)
    
    //Load frames into Clip
    for i: i32 = 0; i < frameCount; i += 1 {
        frameFileName := fmt.aprintf("%s%i.%s", fileName, i, fileType, allocator=context.temp_allocator)
        frameFilePath := filepath.join({directoryPath, frameFileName}, context.temp_allocator)
    
        frameFilePath_C := strings.clone_to_cstring(frameFilePath, context.temp_allocator)
        newAnimation.frames[i] = LoadTexture(frameFilePath_C)
        free_all(context.temp_allocator)
    }

    //All frames added to clip, lkoad into registry
    ref, _ := registry_put(&AnimationRegistry, animationName, newAnimation)
    return ref
}

/*
Will Load an Animation by getting each frame from a spritesheet
and loads the animation into the registry under the provided name
*/
@(private="file")
LoadSheetAnimation :: proc (
    animationName, filePath: cstring,
    frameWidth, frameHeight, xOff, yOff, frameTime, frameCount: i32,
    incrX: i32 = 1,
    incrY: i32 = 0
) -> ^AnimationClip {
    //First check if we are trying to add an already existing element
    alreadyLoaded, _ := registry_has(&AnimationRegistry, animationName)
    //If so, return its reference
    if alreadyLoaded {
        ref, _ := registry_get(&AnimationRegistry, animationName)
        return ref
    }

    //Else, load the element from disk
    newAnimation := animation_clip_create(frameTime, frameCount)

    sourceTexture := LoadTexture(filePath)

    //Load Frames
    for i : i32 = 0; i < frameCount; i += 1 {
        newAnimation.frames[i] = SubImage{
            tex = sourceTexture,
            srcRec = rl.Rectangle{
                width = f32(frameWidth),
                height = f32(frameHeight),
                x = f32(xOff + (i * frameWidth * incrX)),
                y = f32(yOff + (i * frameHeight * incrY))
            }
        }
    }

    //All frames added to clip, load into registry
    ref, _ := registry_put(&AnimationRegistry, animationName, newAnimation)
    return ref
}

/*
Unloads the given Animation
*/
@(private)
UnloadAnimation :: proc(clip: ^AnimationClip) {
    //Free the allocated memory for the frame-array
    delete(clip.frames)

    //.... thats it

    // I don't know why you're still reading, but there isn't anything left to do
}

/*
Creates the framework of an animation (that being it's frameCount and time components as well as it's frame Array)
*/
@(private="file")
animation_clip_create :: proc(
    frameTime, frameCount: i32
) -> AnimationClip {
    return AnimationClip{
        frameCount = frameCount,
        frameTime = frameTime,
        frames = make([]Renderable, frameCount)
    }
}