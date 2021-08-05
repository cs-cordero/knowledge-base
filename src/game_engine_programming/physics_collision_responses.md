# Collision Responses

A collision response is the (hopefully) realistic effect that rigid bodies will perform as a result of being collided with another rigid bodies.

### Energy

When a force moves a body over a distance, the force does _work_.

Work is a change in energy: it either adds energy to a system of rigid bodies, or it removes energy from the system.

Energy has two forms:
1. Potential energy, \\(V\\).
1. Kinetic energy, \\(T\\).

Total energy of an isolated system of rigid bodies is _conserved_ so long as no outside force is performing work on the system.

\\[E = V + T\\]

#### Kinetic Energy

\\[\begin{align}
    T_{\text{linear}} &= \frac{1}{2} m \vec{v}^2 \\\\
                      &= \frac{1}{2} \vec{p} \cdot \vec{v}
\end{align}\\]
\\[T_{\text{angular}} = \frac{1}{2} \vec{L} \cdot \vec{\omega} \\]

#### Physics Simulation Approximations

Most real-time rigid body dynamics simulations approximate actual collision responses using a model called _Newton's law of restitution for instantaneous collisions with no friction_.

Assumptions:
* Collision force acts over an infinitesimally short period of time, meaning it acts as an idealized _impulse_.
* There is no friction at the point of contact between object surfaces.
    * This means that the impulse acting to separate the objects is normal to both surfaces, there is no tangential component.
* The nature of the complex submolecular interactions between the bodies during collision can be approximated using a quantity known as _coefficient of restitution_, \\(\epsilon\\), which describes how much energy is lost during collision.
    * When \\(\epsilon = 1\\), the collision is perfectly elastic and no energy is lost.
    * When \\(\epsilon = 0\\), the collision is perfectly inelastic and the kinetic energy of both bodies are lost, the bodies sticking together and continuing to move in the direction that their mutual center of mass had been moving before the collision.

All collision analyses are founded on the idea that linear momentum is conserved.

\\[ \vec{p_1} + \vec{p_2} = \vec{p_1'} + \vec{p_2'}\\]
\\[ m_1 \vec{v_1} + m_2 \vec{v_2} = m_1' \vec{v_1'} + m_2' \vec{v_2'}\\]

In addition to momentum being conserved, so too is kinetic energy:

\\[
    \frac{1}{2} m_1 \vec{v_1}^2 + \frac{1}{2} m_2 \vec{v_2}^2
    = \frac{1}{2} m_1' \vec{v_1}^2 + \frac{1}{2} m_2 \vec{v_2}^2
    + T_{\text{lost}}
\\]

If the collision is perfectly elastic, energy loss \\(T_{\text{loss}}\\) is zero.

If the collision is perfectly inelastic, energy loss is equal to the original kinetic energy of the system, which requires that the other prime terms must become zero.

#### Applying Newton's law of restitution

An impulse is a force that acts over an infinitesimally short period of time. It causes instantaneous change in the velocity of the bodies it is being applied to.

Impulses in physics textbooks are often denoted as \\(\vec{\hat{p}}\\).  \\(p\\) is used because it is a change in _momentum_.

Since there is no friction, the direction of the impulse is normal to both surfaces at the point of contact.  One body receives \\(\vec{\hat{p}}\\) and the other receives an equal but opposite amount: \\(-\vec{\hat{p}}\\)

> \\[ \vec{\hat{p}} = \hat{p} \vec{n} \\]
> 
> Where:
> * \vec{n} is the unit normal vector.

#### Newton's law of restitution applied to two rigid bodies colliding

> \\[
> \begin{align}
>     \vec{p_1}' &= \vec{p_1} + \vec{\hat{p}} \\\\
>     m_1 \vec{v_1}' &= m_1 \vec{v_1} + \vec{\hat{p}} \\\\
>     \vec{v_1}' &= \vec{v_1} + \frac{\vec{\hat{p}}}{m_1} \vec{n}
> \end{align}
> \\]

> \\[
> \begin{align}
>     \vec{p_2}' &= \vec{p_2} - \vec{\hat{p}} \\\\
>     m_2 \vec{v_2}' &= m_2 \vec{v_2} - \vec{\hat{p}} \\\\
>     \vec{v_2}' &= \vec{v_2} - \frac{\vec{\hat{p}}}{m_2} \vec{n}
> \end{align}
> \\]

#### Coefficient of Restitution

Provides the relationship between the velocities of the bodies before and after colliding.

\\[\left(\vec{v_2}' - \vec{v_1}'\right) = \epsilon \left(\vec{v_2} - \vec{v_1}\right)\\]


Assuming that bodies cannot rotate:

\\[ \vec{\hat{p}} = \hat{p} \vec{n} = \frac{\left(\epsilon + 1\right)\left(\vec{v_2} \cdot \vec{n} - \vec{v_1} \cdot \vec{n}\right)}{\frac{1}{m_1} + \frac{1}{m_2}} \vec{n} \\]

#### Penalty Forces

Penalty forces is an alternative approach to collision response.  It uses imaginary forces called "penalty forces" into the simulation, which act like stiff damped springs attached to the contract points between two bodies that have just interpenetrated (collided).

A spring constant \\(k\\) controls the duration of the interpenetration.

A dampening coefficient \\(b\\) acts like the restitution coefficient.  When \\(b = 0\\), there is no dampening and so the collision is perfectly elastic (no energy is lost).

Penalty forces works well as an approach when many rigid bodies are interpenetrating each other.  It also works well for low-speed impacts, less so for high-speed.

Since it responds to penetration (relative position of the rigid bodies) rather than relative velocity, the forces may have undesirable directions.

#### Friction
* _Static friction_ occurs when starts moving a stationary object to slide along a surface.
* _Dynamic friction_ is a resisting force that occurs when two objects are moving relative to one another.
* _Sliding friction_ is a type of dynamic friction when two objects are sliding against each other.
* _Rolling friction_ is a either static or dynamic and occurs at the point of contact between an object rolling and the surface it is rolling on.
* Surfaces that are rough can cause rolling objects to roll without sliding.
* Surfaces that are smooth allow objects to slip, allowing a dynamic form of rolling friction.
* _Collision friction_ occurs instantaneously ast the point of contact when two bodies collide while moving.

> \\[ f = \mu m g \cos{\theta} \\]
> 
> Where:
> * \\(\mu\\) is the _coefficient of friction_.
> * \\(m g\\) is weight, which is the force of gravity on a mass.
> * \\(\theta\\) is the angle of the gravitational force normal to an inclined surface.


### Sleeping

Physics engines need to determine when an object has come to a rest. This isn't as simple as it seems due to floating-point errors, calculations, and numerical instability that can cause objects to jitter instead of coming to a rest.

Physics engines allow resting bodies to be put to sleep, which excludes them from simulation temporarily.  It will also be important to be able to awaken an object under certain circumstances like when a force or impulse acts upon the object.

Common criteria for determining whether to put an object to sleep:
* The object is _supported_, meaning it has 3+ contact points that allow it to achieve equilibrium with forces acting upon it (like gravity)
* The object has linear and angular momentum below some threshold.
* The object's running average of linear and angular momentum is below some threshold.
* the _total kinetic energy_ is below a predefined threshold. Kinetic energy is used because it's mass-normalized, which allows a single constant can be used for all objects.

### Constraints

Examples of constraints:
* A swinging chandelier (point-to-point constraint)
* Doors that can be kicked, slammed, or blown off of its hinges (hinge constraint).
* A vehicle wheel assembly (axle constraint with damped springs for suspension)
* A train or car pulling a trailer (stiff spring/rod constraint)
* A rope or chain (chain of stiff springs or rods)
* A rag doll

#### Point-to-Point

Simplest form of constraint.

Bodies can move in any way they like as long as a specified point on one body lines up with a specified point on another body.

Think of a ball-and-socket joint.

#### Stiff Springs

Like a point-to-point contact, but it keeps the two points separated by a specified distance.  The objects are free to move otherwise.

#### Hinge Constraints

Limits rotational motion to a single degree of freedom about the hinge's axis.

Unlimited hinges are like a car axle where the wheel can rotate freely infinitely in one or the opposite directions.

Limited hinges are like a door hinge which can only move through a predefined range about the axis.

#### Prismatic Constraints

Acts like a piston.  Kind of a corollary to a hinge constraint but for translational motion:  restricts translational motion to work only along a single degree of freedom.

#### Rag Dolls

Rag dolls are created by linking together a collection of rigid bodies, one for each semi-rigid part of the body.

The linking is done using constraints (specifically constraint chains)

#### Powered Constraints

An external engine system (e.g., the animation system) can indirectly control the translations and orientations of the rigid bodies in a rag doll.








