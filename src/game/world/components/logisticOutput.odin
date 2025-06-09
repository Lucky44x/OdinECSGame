package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

//TODO: Implement

/*
    Logistic Output Component
*/
c_LogisticOutput :: struct {
    itemQueues: []types.Queue(LogisticItem, 1),
    linkedInput: ^c_LogisticIntake,
    linkedSlot: int  
}

t_LogisticOutput: ecs.Table(c_LogisticOutput)