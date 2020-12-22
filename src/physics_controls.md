# Physics Engine Controls

Physics engines need to provide a way to exert control over the rigid bodies in the simulation.

### Gravity

Gravity is technically not a force according to general relativity but the manifestation of the curvature of spacetime.  In games, though, it's modeled as a configurable and constant acceleration.  You could remove it entirely (like if your game takes place in space).


### Forces

A force acts on a rigid body over a finite time interval.  If it were instantaneously, it would be called an _impulse_.

In games, forces are dynamic and can change its direction(s) and magnitude(s) every frame.  A force-application function should be designed to ber called on every frame until the duration is over.

When forces are applied to a rigid body, but not towards its center of mass, it produces a linear _and_ rotational acceleration: a torque.

_Pure torque_ is modeled using a pair (called a _couple_) of forces that are equal, opposite, and applied to points equidistant from the rigid body's center of mass.  This causes it to spin with no linear translation affect.

### Impulse

An impulse is an instantaneous change in momentum.  Games cannot achieve "instantaneous" change in momentum since the shortest possible of duration for a force is \\(\Delta t\\), since that is the physics timestep.

A physics engine usually has an interface for applying a force as an impulse.  The interface distinguishes itself from a force that is applied over a time interval.

Like forces, impulses may apply both linear and rotational forces, or using a _couple_ it may produce a pure torque.

## Physics Steps

On every update step, a typical game engine's physics system performs the following:
1. The forces and torques acting on rigid bodies are integrated forward by \\(\Delta t\\).
1. Collisions are checked as a result of the integrated movement in the previous step.  The rigid bodies keep track of their contact points to take advantage of temporal coherency.
1. Collisions are resolved, usually by applying impulses or penalty forces or constraints.  At this point, this phase may include continuous collision detection (CCD).  Otherwise, it's called time of impact detection (TOI).
1. Constraints are satisfied by a constraint solver.

Even though we check for collisions and try to resolve them in this step, it may result in new positions that cause additional collisions.  An engine will repeat steps 2-4 multiple times until:
1. All collisions are resolved and all constraints are satsified
1. or, a predefined maximum number of iterations have been exceeded.  This allows the frame to continue being processed even if the collisions are all wonky.  We can finish solving the simulation in the next frame.

Check out Open Dynamics Engine (ODE) or PhysX since they are available for free.

### Constraint Solvers

A constraint solver is an iterative error-minimization algorithm, meaning it tries to minimize the error between the actual position and rotation of a rigid body with their ideal position/rotation defined by its constraints.

The integrator in step 1 of the physics time step usually moves rigid bodies out of sync with its constraints, and the constraint solver brings it all back.

