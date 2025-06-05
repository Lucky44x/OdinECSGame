package inspector

import "../../../../libs/clay"
import rl "vendor:raylib"
import "core:fmt"
import ecs "../../../../libs/ode_ecs"

//TODO: Implement
open_inspector :: proc(
    eid: ecs.entity_id,
    db: ^ecs.Database
) {
    fmt.printfln("Open inspector for %i", eid)
}