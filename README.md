## OdinECSGame
This is a small Prototype for a FactoryBuilder-type Game written in Odin, using Raylib and [ode_ecs](https://github.com/odin-engine/ode_ecs)

It is by no means complete
It is by no means functional

It just barely launches and lets you do some shenanigans with a Miner, Smelter and conveyor belts.

Already Implemented:
- Miner (Resource Tap)
- Smelter (Resource Converter)
- Conveyors
- UI (To a semi-functional extent)
- Some Remnants of an old enemy system

It uses Multi-Threading and Parallelism to speed up the factory simulation, as well as a Hashed-Space-Partioned Chunk-System so that it can easily handle Boids and collision logic (originally used for enemy swarms)
