package systems

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import comp "../components"
import "../../../resource"
import "../../profiling"

@(private="file")
v_sprite_renderer_render: ecs.View
@(private="file")
it_sprite_renderer_render: ecs.Iterator

@(private)
init_s_sprite_renderer_render :: proc(
    db: ^ecs.Database
) {
    ecs.view_init(&v_sprite_renderer_render, db, { &comp.t_SpriteRenderer, &comp.t_Transform, &comp.t_Cullable })
    ecs.iterator_init(&it_sprite_renderer_render, &v_sprite_renderer_render)
}

/*
Renders all Sprite-Renderer Components
*/
s_sprite_renderer_render :: proc() {
    profiling.profile_scope("SpriteRenderer System")

    for ecs.iterator_next(&it_sprite_renderer_render) {
        eid := ecs.get_entity(&it_sprite_renderer_render)

        if !check_is_active(eid) do continue

        culled: ^comp.c_Cullable = ecs.get_component(&comp.t_Cullable, eid)
        if culled.culled do continue

        spriteRend: ^comp.c_SpriteRenderer = ecs.get_component(&comp.t_SpriteRenderer, eid)
        transform: ^comp.c_Transform = ecs.get_component(&comp.t_Transform, eid)
        
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

    ecs.iterator_reset(&it_sprite_renderer_render)
}