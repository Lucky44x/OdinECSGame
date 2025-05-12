# ECS Modifier System Design (Odin + od_ecs)

## Overview

This document outlines the design of a modular, scalable modifier system for a Vampire Survivors-like game using the `od_ecs` ECS library in Odin. The focus is on flexibility, performance, and support for infinite upgradability via JSON-defined modifiers.

---

## Core Concepts

### Modifier Entity

Modifiers are represented as standalone entities with a `c_Modifier` component:

```odin
c_Modifier :: struct {
    function: proc(^c_Stats),
    target: entity_id,
}
````

Alternatively, the `target`'s `^c_Stats` pointer can be cached for faster access:

```odin
c_Modifier :: struct {
    stats_ptr: ^c_Stats,
    function: proc(^c_Stats),
}
```

> ⚠️ Ensure the pointer remains valid to avoid dangling memory access.

---

## JSON-Defined Modifiers

Modifiers can be defined in JSON files and parsed at runtime:

```json
{
  "id": "health_up",
  "effects": [
    { "stat": "health", "type": "add", "value": 10 }
  ]
}
```

### Effect Struct

```odin
Effect_Op :: enum { Add, Subtract, Multiply, Divide, Do, SetFlag }

Effect :: struct {
    stat: string,         // Or enum/ID for performance
    op: Effect_Op,
    value: f32,
    condition: string,    // Optional
}
```

---

## Chainable Effects

Multiple effects can be chained and applied in order, e.g.:

```json
"effects": [
  { "stat": "health", "type": "multiply", "value": 2 },
  { "stat": "health", "type": "add", "value": 5 }
]
```

This mimics expression evaluation (`health = health * 2 + 5`) without needing a full parser.

---

## Conditional Effects

Each effect may include a `condition` field, allowing for logic gating:

```json
{
  "stat": "health",
  "type": "add",
  "value": 5,
  "condition": "not_dead"
}
```

These conditions can be:

* Bitflags (e.g., `is_dead`, `on_fire`)
* Evaluated via enum dispatch
* Extended later with expression logic

---

## Event-Type Effects

Effects can also perform actions:

```json
{
  "type": "do",
  "action": "explode",
  "condition": "is_dead"
}
```

Or set flags:

```json
{
  "type": "setFlag",
  "flag": "on_fire",
  "condition": "has_gasoline"
}
```

Dispatch tables or function pointers should be used to map `action` and `flag` strings to logic efficiently.

---

## Runtime Parsing Workflow

1. **Read JSON file** on modifier pickup / trigger.

2. **Parse into `ModifierDefinition` struct**:

   ```odin
   ModifierDefinition :: struct {
       id: string,
       effects: []Effect,
   }
   ```

3. **Generate function or component**:

   * Either generate a `proc(^c_Stats)` that applies all effects
   * Or store `[]Effect` in a `c_ModifierRuntime` and interpret it each frame

4. **Attach to modifier entity** and let ECS systems handle the rest.

---

## Performance Considerations

| Operation                    | Cost       | Notes                            |
| ---------------------------- | ---------- | -------------------------------- |
| `get(entity, c_Stats)`       | O(1)       | Fast, but avoid if possible      |
| `^c_Stats` direct pointer    | O(1)       | Faster, but must ensure validity |
| Math ops in `Effect`         | Negligible | Simple arithmetic                |
| Flag check                   | O(1)       | Use bitmasks                     |
| Action dispatch (`do`, etc.) | Low        | Use enum or function tables      |
| JSON parsing                 | Once       | Done at modifier instantiation   |

---

## Possible Enhancements

* **Expose properties via `c_ExposedProperty`** component to support referencing stats like `"items"`, `"speed"`, etc.
* **Mini expression evaluator** for advanced dynamic modifiers (`"value": "items * 5 + 1"`).
* **Modifier caching** to avoid repeated parsing of same JSON.
* **Script integration** (e.g., Lua) for fully dynamic events.

---

## Summary

This modifier system enables:

* Modular, reusable stat effects
* JSON-driven upgrades and conditions
* Efficient per-frame evaluation
* Easy extension for new logic, triggers, or game systems

It balances runtime flexibility with good ECS design and high performance.