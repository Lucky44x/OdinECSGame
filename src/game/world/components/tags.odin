package components

import ecs "../../../../libs/ode_ecs"
import rl "vendor:raylib"
import "../tagging"

/*
    Tags Component and Table
*/
c_Tags :: tagging.TagContainer

t_Tags: ecs.Table(c_Tags)