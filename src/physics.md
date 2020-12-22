# Collision & Physics

A game engine's collision system is often closely integrated with a _physics engine_.  In games, "physics" is more accurately described as _rigid body dynamics_ simulation.
* A `rigid body` is an idealized, infinitely hard, non-deformable solid object.
* `Dynamics` refers to the process of determining how these rigid bodies *move* and *interact* over time under the influence of *forces*.

Dynamics simulation makes heavy use of the collision detection system to properly simulate certain behaviors of objects in the simulation (like bouncing, sliding, rolling, coming to rest, falling, etc.)

You DO NOT need a dynamics simulation in order to have a collision system.  Many games do not have a "physics system" at all.

**But all games involving objects in 2D or 3D space have some form of collision detection**.


### What a Physics engine can do

* Rag doll physics
* Powered rag doll (a blend of traditional animation and rag doll physics)
* Ropes, cloth, hair
* Fluid mechanics effects (including buoyancy)
* Simulation of deformable bodies
* Detect collisions between dynamic objects and static world geometry
* Simulate free rigid bodies under the influence of gravity and other forces.
* Spring-mass systems
* Destructible buildings and structures
* Ray and shape casts (determines line of sight, bullet impacts, etc.)
* Trigger volumes (determine when objects enter, leave or are inside predefined regions in the game world).
* Complex machines (cranes, moving platforms, etc.)
* Traps (avalanches, rocks falling, etc.)
* Vehicles with realistic suspensions
* Audio propagation

### Impacts of Physics on a Game
* Predictability: since the effect of some simulation might not be known beforehand, you lose some predictability on what might happen.  If something must absolutely must happen a certain way, it's better to animate than to coerce a physics engine into working a specific way.
* Tuning and control: generally the laws of physics are fixed. You can tweak their values offline to achieve your desired effect.  You can even tweak them at runtime, but their effects may be hard to visualize.
* Unexpected behaviors: rocket-launcher jump trick, various Breath of the Wild physics exploits (see speed runners).
* Tools pipelines: a good physics/collision pipeline takes time to build and maintain.
* User interface: the way in which a player actually interacts with and causes physics objects to change is going to be important.
* Collision detection: objects intended for dynamics simulation need to be carefully constructed.
* AI gets much harder, especially for pathing, due to the unpredictability of the simulation.
* Misbehaved objects: objects may act in really unexpected ways (see Bethesda Elder Scrolls games)
* Rag doll physics: When objects become rag doll, it can cause instability (see again Elder Scrolls games, Bethesda Fallout games)
* Graphics: changes in physical objects may invalidate precomputed lighting and shadows.
* Networking and multiplayer: physics that has an effect on gameplay (like a grenade that might damage multiple players) must be simulated on the server and replicated on all clients.  If the physics effect does not have an effect on gameplay, the physics may be simulated on each client machine.
* Record and playback: Due to the unpredictability of a physics engine, you might lose the ability to record and playback an effect since do this requires deterministic effects. It should be noted that it _is possible_ to create a deterministic physics engine.  Record and playback is useful as a debugging/testing aid.
* Art assets: to rig up objects with mass, friction, constraints, and other attributes requires the art assets to include them when exporting the objects.
* Duplication of assets: even if you have two of the same object, you might need to duplicate them for different dynamics configurations.  This may make organization harder.


### Commercial and Open Source Physics Middleware

#### Open Dynamics Engine (ODE)

[https://www.ode.org](https://www.ode.org)

* Open source
* Rigid body dynamics SDK
* Similar to Havok engine

#### Bullet

[https://www.bulletphysics.com](https://www.bulletphysics.com)

* Open source
* Collision detection and physics library used by game and film industries
* Supports `Continuous Collision Detection` (CCD), which is useful for small, fast moving objects.

#### TrueAxis

[https://trueaxis.com](https://trueaxis.com)

* Closed source
* Collision and physics SDK

#### PhysX

[https://www.nvidia.com/object/nvidia_physx.html](https://www.nvidia.com/object/nvidia_physx.html)

* Closed source
* Owned by NVIDIA, runs on NVIDIA's GPUs as a coprocessor.
* Can run on the CPU without GPU support
* The CPU-only version is available for free.
* Combined with APEX, NVIDIA's scalable multiplatform dynamics framework, it can run on many different systems, e.g., Windows, Linux, Mac, Android, Xbox, Playstation, Wii, etc.

#### Havok

[https://havok.com](https://havok.com)

* Closed source
* The "gold standard in commercial physics SDKs"
* Provdies the richest feature sets available and boasting excellent performance on all supported platforms.
* Most expensive
* Has a core collision/physics engine, plus optional add-on products including vehicle physics, destructible environments, fully featured animation SDK, rag doll system, etc.

#### Physics Abstraction Layer (PAL)

[https://www.adrianboeing.com/pal/index.html](https://www.adrianboeing.com/pal/index.html)

* Open source
* Library that allows you to work with more than one physics SDK
* Provides hooks for PhysX, Newton, ODE, OpenTissue, Tokamak, TrueAxis, plus more.

#### Digital Molecular Matter (DMM)

[https://www.pixeluxentertainment.com](https://www.pixeluxentertainment.com)

* Closed source
* Simulates deformable bodies and breakable objects using "finite element methods"

