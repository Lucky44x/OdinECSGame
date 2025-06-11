package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

/*
    Logistic Passthrough Component
*/
c_LogisticPassthrough :: struct {
    linkedInput: ^c_LogisticIntake,
    linkedInputSlot: u8,
    linkedOutput: ^c_LogisticOutput,
    linkedOutputSlot: u8
}

t_LogisticPassthrough: ecs.Table(c_LogisticPassthrough)