package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

/*
    Logistic Intake Component
*/
c_LogisticIntake :: struct {
    isValid: bool,
    itemQueues: []LogisticStack,
    linkedPassthrough: []^c_LogisticPassthrough
}

t_LogisticIntake: ecs.Table(c_LogisticIntake)

add_intake :: proc(
    eid: ecs.entity_id,
    numIntakes: u8
) -> ^c_LogisticIntake {
    intake, _ := ecs.add_component(&t_LogisticIntake, eid)
    if numIntakes == 0 do return intake

    intake.itemQueues = make([]LogisticStack, numIntakes)
    intake.linkedPassthrough = make([]^c_LogisticPassthrough, numIntakes)
    intake.isValid = true

    return intake
}

reset_intake :: proc(
    intake: ^c_LogisticIntake
) {
    if !intake.isValid do return

    delete(intake.itemQueues)
    delete(intake.linkedPassthrough)
}