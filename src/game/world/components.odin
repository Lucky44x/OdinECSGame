package world

import rl "vendor:raylib"
import "core:math/linalg"
import "../../resource"
import ecs "../../../libs/ode_ecs"

import "core:fmt"

// General Datatypes
LookatTarget :: union {
    LookatMouse,
    LookatTransform
}

LookatMouse :: struct{}
LookatTransform :: ^c_Transform

// Component DEFS

c_MovementStats :: struct {
    speed, acceleration: f32
}

c_Transform :: struct {
    position, scale, origin: rl.Vector2,
    rotation: f32
}

c_TransformChild :: struct {
    offsetPosition, offsetScale: rl.Vector2,
    offsetRotation: f32,
    parent: ^c_Transform
}

c_TransformLookAt :: struct {
    target: LookatTarget
}

c_Velocity :: struct {
    velocity: rl.Vector2,
    angular_velocity: rl.Vector2,
    deceleration_coeff: f32
}

c_SpriteRenderer :: struct {
    flipX, flipY: bool,
    sprite: resource.Renderable,
    color: rl.Color
}

c_Cullable :: struct{
    culled: bool
}

// Table DEFS
t_Transform: ecs.Table(c_Transform)
t_TransformChild: ecs.Table(c_TransformChild)
t_Velocity: ecs.Table(c_Velocity)
t_SpriteRenderer: ecs.Table(c_SpriteRenderer)
t_TransformLookAt: ecs.Table(c_TransformLookAt)
t_MovementStats: ecs.Table(c_MovementStats)
t_Cullable: ecs.Table(c_Cullable)

//Views
v_SpriteRendering: ecs.View
it_SpriteRendering: ecs.Iterator

v_TransformChildren: ecs.View
it_TransformChildren: ecs.Iterator

v_TransformLookat: ecs.View
it_TransformLookat: ecs.Iterator

v_VelocityApplication: ecs.View
it_VelocityApplication: ecs.Iterator

v_CullingSystem: ecs.View
it_CullingSystem: ecs.Iterator

//Systems
/*
Renders all Sprite-Renderer Components
*/
s_sprite_renderer_render :: proc() {
    for ecs.iterator_next(&it_SpriteRendering) {
        eid := ecs.get_entity(&it_SpriteRendering)
        culled: ^c_Cullable = ecs.get_component(&t_Cullable, eid)

        if culled.culled do continue

        spriteRend: ^c_SpriteRenderer = ecs.get_component(&t_SpriteRenderer, eid)
        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)
        
        renderPosition := transform.position
        dstRec := rl.Rectangle{ renderPosition[0], renderPosition[1], transform.scale[0], transform.scale[1] }

        multW, multH : f32 = spriteRend.flipX ? -1 : 1, spriteRend.flipY ? -1 : 1
        multX, multY : f32 = spriteRend.flipX ? 1 : 0, spriteRend.flipY ? 1 : 0
        origin_px := transform.scale * transform.origin

        //Render shit
        switch type in spriteRend.sprite {
            case ^rl.Texture2D:
                //rl.DrawTextureEx(type^, transform.position, transform.rotation, transform.scale[0], rl.WHITE)
                width, height := f32(type.width) * transform.scale[0], f32(type.height) * transform.scale[1]
                srcRec := rl.Rectangle{
                    f32(type.width) * multX,
                    f32(type.height) * multY,
                    f32(type.width) * multW, f32(type.height) * multH
                }
                
                rl.DrawTexturePro(type^, srcRec, dstRec, origin_px, transform.rotation, spriteRend.color)
                break
            case resource.SubImage:
                srcRec := type.srcRec
                srcRec.x += type.srcRec.width * multX
                srcRec.y += type.srcRec.height * multY
                srcRec.width *= multW
                srcRec.height *= multH
                
                rl.DrawTexturePro(type.tex^, srcRec, dstRec, origin_px, transform.rotation, spriteRend.color)
                break
            case resource.PrimitiveEllipse:
                rl.DrawEllipse(i32(renderPosition[0]), i32(renderPosition[1]), transform.scale[0], transform.scale[1], spriteRend.color)
                break
            case resource.PrimitvieRect:
                rl.DrawRectanglePro(dstRec, origin_px, transform.rotation, spriteRend.color)
                break
        }
    }

    ecs.iterator_reset(&it_SpriteRendering)
}

/*
Updates child-transforms to follow their parent's position, rotation and scale
*/
s_children_transform_update :: proc() {
    for ecs.iterator_next(&it_TransformChildren) {
        eid := ecs.get_entity(&it_TransformChildren)
        
        //spriteRend: ^c_SpriteRenderer = ecs.get_component(&t_SpriteRenderer, eid)
        childTransform: ^c_TransformChild = ecs.get_component(&t_TransformChild, eid)
        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)
        //Dereference so we cannot modify the parent
        parentTransform: c_Transform = childTransform.parent^

        //Rotate the offset around origin
        relative_offset := childTransform.offsetPosition * parentTransform.scale
        rotatedOffset := rl.Vector2Rotate(relative_offset, parentTransform.rotation * rl.DEG2RAD)

        //Apply transforms to base-transform
        transform.rotation = parentTransform.rotation + childTransform.offsetRotation
        transform.position = parentTransform.position + rotatedOffset
        transform.scale = parentTransform.scale * childTransform.offsetScale
    }

    ecs.iterator_reset(&it_TransformChildren)
}

/*
Rotates a Transform to look at a specific target
*/
s_transform_lookat_target :: proc() {
    targetPos: rl.Vector2 = rl.GetMousePosition()
    forward: rl.Vector2 = { 0, 1 }

    for ecs.iterator_next(&it_TransformLookat) {
        eid := ecs.get_entity(&it_TransformLookat)

        culled := ecs.get_component(&t_Cullable, eid)
        if culled.culled do continue

        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)
        transformLookAt: ^c_TransformLookAt = ecs.get_component(&t_TransformLookAt, eid)
        myPos: rl.Vector2 = transform.position

        switch type in transformLookAt.target {
            case LookatMouse:
                targetPos = rl.GetMousePosition() + GameCamera.target
                break
            case ^c_Transform:
                targetPos = type.position
                break
        }

        lookDir := targetPos - myPos
        angle := linalg.atan2(lookDir[1], lookDir[0]) - linalg.atan2(forward[1], forward[0])

        //Do Transformations
        transform.rotation = angle * rl.RAD2DEG

        //rl.DrawLine(i32(targetPos[0]), i32(targetPos[1]), i32(myPos[0]), i32(myPos[1]), rl.RED)
    }

    ecs.iterator_reset(&it_TransformLookat)
}

/*
Moves every Transform by its Velocity Vector
*/
s_apply_velocity :: proc() {
    for ecs.iterator_next(&it_VelocityApplication) {
        eid := ecs.get_entity(&it_VelocityApplication)

        vel: ^c_Velocity = ecs.get_component(&t_Velocity, eid)
        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)

        transform.position += vel.velocity
        vel.velocity *= vel.deceleration_coeff
    }

    ecs.iterator_reset(&it_VelocityApplication)
}

/*
Sets the respective entities to be culled, when outside view-frustum (as described in camera.odin)
*/
s_cull_entities :: proc() {
    for ecs.iterator_next(&it_CullingSystem) {
        eid := ecs.get_entity(&it_CullingSystem)

        cullingData: ^c_Cullable = ecs.get_component(&t_Cullable, eid)
        transform: ^c_Transform = ecs.get_component(&t_Transform, eid)

        targetRect := rl.Rectangle{
            x = transform.position[0],
            y = transform.position[1],
            width = transform.scale[0],
            height = transform.scale[1]
        }

        if rl.CheckCollisionRecs(CameraFrustum, targetRect) do cullingData.culled = false
        else do cullingData.culled = true
    }

    ecs.iterator_reset(&it_CullingSystem)
}

//General Functions
/*
Initializes the general Components, their respective Tables and Views
*/
init_comp_general :: proc(db: ^ecs.Database) {
    //Initialize Component Tables
    ecs.table_init(&t_Transform, db, 5000)
    ecs.table_init(&t_TransformChild, db, 5000)
    ecs.table_init(&t_Velocity, db, 5000)
    ecs.table_init(&t_SpriteRenderer, db, 5000)
    ecs.table_init(&t_TransformLookAt, db, 5000)
    ecs.table_init(&t_MovementStats, db, 5000)
    ecs.table_init(&t_Cullable, db, 5000)

    //Initialize views
    ecs.view_init(&v_SpriteRendering, db, {&t_SpriteRenderer, &t_Transform, &t_Cullable})
    ecs.iterator_init(&it_SpriteRendering, &v_SpriteRendering)

    ecs.view_init(&v_CullingSystem, db, { &t_Transform, &t_Cullable })
    ecs.iterator_init(&it_CullingSystem, &v_CullingSystem)

    ecs.view_init(&v_TransformChildren, db, {&t_Transform, &t_TransformChild})
    ecs.iterator_init(&it_TransformChildren, &v_TransformChildren)

    ecs.view_init(&v_TransformLookat, db, {&t_Transform, &t_TransformLookAt})
    ecs.iterator_init(&it_TransformLookat, &v_TransformLookat)

    ecs.view_init(&v_VelocityApplication, db, {&t_Transform, &t_Velocity})
    ecs.iterator_init(&it_VelocityApplication, &v_VelocityApplication)
}