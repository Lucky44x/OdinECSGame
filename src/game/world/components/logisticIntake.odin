package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import types "../../../../libs/datatypes"

//TODO: Immplement

/*
    Logistic Intake Component
*/
c_LogisticIntake :: struct {
    itemQueues: []types.Queue(LogisticItem, 1)   
}

t_LogisticIntake: ecs.Table(c_LogisticIntake)