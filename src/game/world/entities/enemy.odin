package entities

import rl "vendor:raylib"
import ecs "../../../../libs/ode_ecs"
import comps "../components"
import "../../../resource"
import types "../../../../libs/datatypes"

@(private="file")
EnemyPool: types.Pool(ecs.entity_id, 1024)