package world

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"

CameraShakeSettings :: struct {
    duration, magnitude: f32
}

@(private="file")
CameraShakeCommand :: struct {
    settings: CameraShakeSettings,
    elapsed: f32,
    active: bool,
    offset: rl.Vector2
}

GameCamera := rl.Camera2D{
    target = { 0, 0 },
    zoom = 1,
    rotation = 0
}

@(private="file") FrustumMargin: rl.Vector2
CameraFrustum: rl.Rectangle

@(private="file") currentShake: CameraShakeCommand = {}

/*
Will start a new shake, with the provided parameters,
as long as there is currently no shake running

(set duration <= -1 to make it infinite until stop_shake is called)
*/
camera_shake :: proc(
    settings: CameraShakeSettings
) {
    if currentShake.active do return

    currentShake.settings = settings
    currentShake.elapsed = 0
    currentShake.active = true
}

/*
Will stop the current shake
*/
camera_stop_shake :: proc() {
    currentShake.active = false
}

/*
Will initialize the camera systems
*/
camera_init :: proc() {
    FrustumMargin = {
        f32(rl.GetScreenWidth()) / 4,
        f32(rl.GetScreenHeight()) / 4
    }
    CameraFrustum.width = f32(rl.GetScreenWidth()) + FrustumMargin[0]
    CameraFrustum.height = f32(rl.GetScreenHeight()) + FrustumMargin[1]
}

/*
Will update the Camera (Handle the logic for when there is a camera shake currently active)
*/
camera_update :: proc() {
    CameraFrustum.x = GameCamera.target[0] - (FrustumMargin[0] / 2)
    CameraFrustum.y = GameCamera.target[1] - (FrustumMargin[1] / 2)

    if !currentShake.active do return

    delta := rl.GetFrameTime()
    currentShake.elapsed += delta

    if currentShake.settings.duration > -1 && currentShake.elapsed >= currentShake.settings.duration {
        
        //fmt.printfln("Shake has elapsed: %f", currentShake.elapsed)
        
        currentShake.active = false
        GameCamera.offset = { 0, 0 }
        return
    }

    //fmt.printfln("Doing Shake")

    decay: f32 = 1
    if currentShake.settings.duration > -1 {
        t := currentShake.elapsed / currentShake.settings.duration
        decay = 1 - t //fade out over time
    }

    offsetX := rand.float32_range(-1, 1)
    offsetY := rand.float32_range(-1, 1)

    GameCamera.offset = { offsetX, offsetY } * currentShake.settings.magnitude * decay
}