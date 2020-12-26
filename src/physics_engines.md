# Physics Engines in Game Engines

Game Objects and Rigid bodies must be linked to each other and to the visual representations on the screen.
* Rigid bodies are only ever drawn in debug mode.
* The linkage betwen a rigid body and its visual representation is usualy indirect - through the logical game object.
* Any game object can be represented by zero or more rigid bodies.
    * 0: A game object with no rigid bodies acts as though they're not solid, like a ghost!  This is a common technique for decorative objects, like birds flying above the player.
    * 1: This is the most common situation where there is a 1:1 mapping of game object to rigid body.  The rigid body approximates the shaope of the game object, but need not be exact.
    * 2+: If a game object has a skeleton, one technique is to have a rigid body corresponding to the joints in the skeleton.
  
Game engine objects usually manage its own rigid bodies and may create and destroy them when necessary, which adds or removes them from the physics world.

### Physics-Driven Bodies
We might want some game objets to be driven _entirely_ by the physics simulation.

Examples:
* Exploding debris
* Rocks rolling down a hill
* Random expelled objects like magazine casings and bullet casings.

We step forward the simulation, then query the physics system for the rigid body's position and orientation.  This transform is applied to the game object, or a joint, or some other data structure within the game object.


### Game-Driven Bodies
Some game objects will have their motions determined by an animation or be under control by a human player.  We would want their rigid bodies to participate in collision detection and affect the physics simulation, but the physics system should not dictate their motion.

* They do not experience gravity
* They are considered to be infinitely massive by the physics system. (Meaning that the simulation cannot change its velocity due to a collision).

Game driven bodies are usually moved using impulses.
* Setting the rigid body's position and orientation to match its corresponding game object introduces discontinuities that might make it difficult for the physics system to resolve.
* Most physics SDKs provide a convenience function that calculates the linear and angular impulses required to reach a desired position on the next frame.


***A single rigid body may switch between being game-driven or physics-driven***.


### Fixed Bodies
These are static game objects (e.g., walls) with rigid bodies that do not participate in the dynamics simulation at all.  They are, therefore, collision-only bodies.


## Simulation Updating
The physics simulation is stepped forward periodically, usually once per frame. The following steps are taken:

1. Update game-driven rigid bodies.
  * The transforms of all game-driven rigid bodies are updated to match their game objects in the game world.
1. Update phantoms
  * Phantoms are game-driven collidables with no corresponding rigid body, which allows them to perform certain kinds of collision queries.
1. Update forces, apply impulses, and adjust constraints.
  * Any forces applied by teh game are updated.
  * Any impulses caused by game events are applied.
  * Constraints are adjusted and/or removed if necessary.
1. Step the simulation
  * Numerically integrate the equations of motion to find the physical state of all bodies on the next frame.
  * Run collision detection to add/remove contacts from all rigid bodies in the physics world.
  * Resolve collisions and apply constraints.
1. Update physics-driven game objects.
1. Query phantoms
  * The contact points of each phantom are read and used to make decisions on what to do next.
1. Perform collision cast queries
  * Fire off ray and/or shape casts, looking for collisions and reacting appropriately.

### Deciding when to perform a collision query
It's actually not easy to determine when during the frame to perform a collision query.

For up-to-date information, you'd want to query the collision system after the physics step.  But the physics step is usually run near the end of the frame.

Options:
1. Perform your collision queries using last frame's state.
   * This means do your collision queries _before_ the physics step.
1. Accept a one-frame lag in collision requests.
    * This means do your collision queries _before_ the physics step, but treating the results as if they were approximations for the end of the current frame.
1. Run queries after the physics step.
    * This is feasible when the results of the query can safely be deferred until late in the frame.


From `Game Engine Architecture by Jason Gregory`:

```cpp
F32 dt = 1.0f/30.0f;

for (;;) // main game loop
{
    g_hidManager->poll();
    
    g_gameObjectManager->preAnimationUpdate(dt);
    g_animationEngine->updateAnimations(dt);
    g_gameObjectManager->postAnimationUpdate(dt);
    
    g_physicsWorld->step(dt);
    g_animationEngine->updateRagDolls(dt);
    
    g_gameObjectManager->postPhysicsUpdate(dt);
    g_animationEngine->finalize();
    
    g_effectManager->update(dt);
    g_audioEngine->update(dt);
    
    // etc.
    
    g_renderManager->render();
    
    dt = calcDeltatime();
}
```


