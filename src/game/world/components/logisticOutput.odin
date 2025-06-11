package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

/*
    Logistic Output Component
*/
c_LogisticOutput :: struct {
    isValid: bool,
    itemQueues: []LogisticStack,
    linkedPassthrough: []^c_LogisticPassthrough
}

t_LogisticOutput: ecs.Table(c_LogisticOutput)

add_output :: proc(
    eid: ecs.entity_id,
    numOutputs: u8
) -> ^c_LogisticOutput {
    output, _ := ecs.add_component(&t_LogisticOutput, eid)
    if numOutputs == 0 do return output

    output.itemQueues = make([]LogisticStack, numOutputs)
    output.linkedPassthrough = make([]^c_LogisticPassthrough, numOutputs)
    output.isValid = true

    return output
}

reset_output :: proc(
    output: ^c_LogisticOutput
) {
    if !output.isValid do return //If port was initialized with 0 size, we didn't build anaything

    delete(output.itemQueues)
    delete(output.linkedPassthrough)
}