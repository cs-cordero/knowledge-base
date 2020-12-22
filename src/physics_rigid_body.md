# Rigid Body Dynamics

Game engines are concerned with a ubset of physics called _dynamics_, which is the study of how forces affect the movement of objects.

* _Newtonian mechanics_:  the objects in simulation obey Newton's laws of motions.  There are no quantum effects, and speeds are low enough to not have relativistic effects.
* _Rigid bodies_: all objects are perfectly solid and cannot be deformed.  Shape is constant.  This greatly simplifies the mathematics required to simulate the dynamics of solid objects.

Physics engines are also intended to have realistic effects for the following:
* No interpenetrating objects (collisions look real)
* Hinges
* Wheels
* Ball joints
* Rag dolls
* Prismatic joints (sliders)

There is usually a one-to-one mapping of rigid bodies to collidables.

Every frame, we need to query the physics engine for the transform of every rigid body and apply it in some way to the transform of the corresponding game object.

See "Grant R. Fowles and George L. Cassiday. Analytical Mechanics, Seventh Edition. Pacific Grove, CA: Brooks Cole, 2005." for foundations in dynamics.
See also: [https://chrishecker.com/Rigid_Body_Dynamics](https://chrishecker.com/Rigid_Body_Dynamics)


### Units

`meters (m)` for distance/length.

`kilograms (kg)` for mass.

`seconds (s)` for time.

### Linear and Angular Dynamics

An _unconstrained_ rigid body translates and rotates freely along all three Cartesian axes.  Such a body has six degrees of freedom (DOF).

* Linear dynamics:  the description of the motion of a rigid body, ignoring rotational effects.
* Angular dynamics: the description of the rotational motion of a rigid body.

### Center of dynamics

In linear dynamics, an unconstrained rigid body acts as though all of its mass were concentrated on its _center of mass_.

A body with uniform density has its center of mass at the centroid of the body.

Convex bodies always have its center of mass inside the body.  Concave bodies can have its center of mass outside the body.

### Linear Dynamics

A rigid body is described by a position vector identifying the location of its center of mass, \\(\vec{r}\\).  Position is measure in meters.

#### Linear Velocity and Acceleration

The derivative of position with respect to time is velocity.

\\[ \vec{v}(t) = \frac{d \vec{r}(t)}{dt} \\]

Differentiating a vector is the same as differentiating each component independently.

\\[ v_x(t) = \frac{d r_x(t)}{dt} = r_x(t) \\]

... and so on for y- and z- components.

The second derivative of position with respect to time is acceleration.

\\[ \vec{a}(t) = \frac{d \vec{v}(t)}{dt} = \frac{d^2 \vec{r}(t)}{dt^2} \\]

### Force and Momentum

A _force_ is anything that causes an object with mass to accelerate or decelerate.  Force has magnitude and direction in space and are therefore represented as vectors.

Net effect of \\(N\\) forces on a body:

\\[ F_{\text{net}} = \sum_{i=1}^N F_i \\]

Newton's Second Law states that force is proportional to acceleration and mass:

\\[ F(t) = m \vec{a}(t) \\]

Forces are measured in terms of \\(\frac{kg-m}{s^2}\\).

A rigid body's linear momentum is its linear velocity multiplied by its mass, denoted with symbol \\(p\\).  (This is confusingly NOT position!)

\\[ \vec{p}(t) = m \vec{v}(t) \\]


### Ordinary Differential Equations

An _ordinary differential equation_ (ODE) is an equation involvin ga function of one independent variable and various derivatives of that function.  If independent variable is time, and the function is \\(x(t)\\), then an ODE is:

\\[ \frac{d^n x}{dt^n} = f \left( t, x(t), \frac{dx(t)}{dt}, \frac{d^2 x(t)}{dt^2}, \cdots, \frac{d^{n-1} x(t)}{dt^{n-1}} \right) \\]


### Analytical Solutions

Differential equations of motion can rarely be solved _analytically_, which is the process of finding a simple, closed-form function that describes the rigid body's position for _all possible values of time_ \\(t\\).

In games this is usually impossible to find because closed-form solutions to some differential equations are not known.  Games are also interactive and so you have no idea a priori how forces will interact over time.


### Numerical Integration

Numerical integration solves differential equations using a _time-stepped_ approach.  We use the solution from a previous timestep to arrive at the solution for the next time step.

The duration of the timestep is usually fixed, \\(\Delta t\\).


#### Explicit Euler

A simple numerical solution to an ODE, and the most intuitive.

Assuming we know the current velocity, \\(\vec{v}(t)\\) and we want to solve the following ODE to find the rigid body's position on the next frame:

\\[ \vec{v}(t) = \vec{r}'(t) \\]

We convert velocity from \\(\frac{m}{s}\\) to \\(\frac{m}{\text{frame}}\\) by multiplying velocity by the time delta, then add "one frame's worth" of velocity onto the current position.

\\[ \vec{r}(t_1) = \vec{r}(t_0) + \vec{v}(t_0) \Delta t \\]

This assumes that velocity is constant during the timestep.

By definition any derivative is the quotient of two infinitesimally small differences, \\(\frac{d\vec{r}}{dt}\\).  Explicit Euler approximates this using the quotient of two _finite_ differences.

\\[\begin{align}
    \frac{d\vec{r}}{dt} &\approx \frac{\Delta \vec{r}}{\Delta t'} \\\\
    \vec{v}(t_0) &\approx \frac{\vec{r}(t_1) - \vec{r}(t_0)}{t_1 - t_0}
\end{align}\\]


Numerical solutions to ordinary differential equations have three properties:
* Convergence: as \\(\Delta t\\) trends toward zero, does the approximate solution trend towards the real solution?
* Order: How bad is the error between the real solution and the approximated solution?  It is usually reflected in big O notation, scaling with the size of \\(\Delta t\\).
* Stability: does the numerical solution tend to find a stable equilibrium over time?
    * If a numerical method adds energy into the system, velocities will eventually "explode", and the system will become unstable.  If a numerical method removes energy from the system, it will have an overall damping effect, and the system will become stable.
    
    
#### Verlet Integration

Explicit Euler is simple but has high error and poor stability.
    
Alternatives include:
* Backward Euler
* Midpoint Euler
* Runge-Kutta methods, e.g., RK4

See [https://en.wikipedia.org/wiki/Numerical_ordinary_differential_equations](https://en.wikipedia.org/wiki/Numerical_ordinary_differential_equations).


The most widely used method is called Verlet Integration.  There is `regular Verlet` and `velocity Verlet`.

##### Regular Verlet

Regular Verlet is great because it offers a low error, is simple, and inexpensive to calculate.  It works by adding two Taylor series expansions, one going forward in time and another going backward in time.

\\[ \vec{r}(t_0 + \Delta t) = \vec{r}(t_0) + \vec{r}(t_0) \Delta t + \vec{r}'(t_0) \Delta t + \frac{1}{2} \vec{r}''(t_0) \Delta t^2 + \frac{1}{6} \vec{r}^{(3)}(t_0) \Delta t^3 + O(\Delta t^4) \\]

\\[ \vec{r}(t_0 - \Delta t) = \vec{r}(t_0) + \vec{r}(t_0) \Delta t - \vec{r}'(t_0) \Delta t + \frac{1}{2} \vec{r}''(t_0) \Delta t^2 - \frac{1}{6} \vec{r}^{(3)}(t_0) \Delta t^3 + O(\Delta t^4) \\]

Adding these two together causes negative terms to cancel, which results in the regular Verlet method:

\\[ \vec{r}(t_0 + \Delta t) = 2 \vec{r}(t_0) - \vec{r}(t_0 - \Delta t) + \vec{a}(t_0) \Delta t^2 + O(\Delta t^4) \\]

If you want to express \\(\vec{a}\\) in terms of net force, since \\(F = ma\\), you can replace it with \\(\frac{F_{\text{net}}(t_0)}{m}\\).


##### Velocity Verlet

This is even more common than regular Verlet, it is a four-step process.

Given \\(\vec{a}(t_0) = \frac{1}{m} \vec{F}\left(t_0, \vec{r}(t_0), \vec{v}(t_0)\right)\\):
1. Calculate \\(\vec{r}(t_0 + \Delta t) = \vec{r}(t_0) + \vec{v}(t_0) \Delta t + \frac{1}{2} \vec{a}(t_0) \Delta t^2 \\).
2. Calculate \\(\vec{v}(t_0 + \frac{1}{2} \Delta t) = \vec{v}(t_0) + \frac{1}{2} \vec{a}(t_0) \Delta t\\).
3. Determine \\(\vec{a}(t_0 + \Delta t) = \vec{a}(t_1) = \frac{1}{m} \vec{F} \left( t_1, \vec{r}(t_1), \vec{v}(t_1) \right)\\).
4. Calculate \\(\vec{v}(t_0 + \Delta t) = \vec{v}(t_0 + \frac{1}{2} \Delta t) + \frac{1}{2}\vec{a}(t_0 + \Delta t) \Delta t \\)


### Angular Dynamics

See:
* [https://gafferongames.com/game-physics/physics-in-3d](https://gafferongames.com/game-physics/physics-in-3d)
* [https://www-2.cs.cmu.edu/~baraff/sigcourse/notesd1.pdf](https://www-2.cs.cmu.edu/~baraff/sigcourse/notesd1.pdf)

Rigid bodies have different moments of inertia about different axes, since they have different distribution of mass about these axes.

The `intertia tensor` is a 3x3 matrix that represents a rigid body's rotational mass.

\\[ I = \begin{bmatrix}
    I_{xx} & I_{xy} & I_{xz} \\\\
    I_{yx} & I_{yy} & I_{yz} \\\\
    I_{zx} & I_{zy} & I_{zz}
\end{bmatrix}
\\]

The non-diagonal elements are usually 0 in games because they produce unintuitive motions.  As a result, the inertia tensor is usually simplified down to \\( I = \begin{bmatrix} I_{xx} & I_{yy} & I_{zz} \end{bmatrix} \\).

Orientation is defined in 3D using unit quaternions.  Alternatives:
* A 3x3 rotational matrix (uses more space than needed)
* Euler angles, \\( \begin{bmatrix} \theta_x & \theta_y & \theta_z \end{bmatrix} \\) (suffers from gimbal lock and more difficult mathematically).

\\[
\begin{align}
    q &= \begin{bmatrix} q_x & q_y & q_z & q_w \end{bmatrix} \\\\
    &= \begin{bmatrix} \vec{q} & q_w \end{bmatrix} \\\\
    &= \begin{bmatrix} \vec{u} \sin \frac{\theta}{2} & \cos \frac{\theta}{2} \end{bmatrix}
\end{align}
\\]

If no forces are acting on a rigid body, then linear acceleration is zero and linear velocity is constant.

If no forces are acting on a rigid body, then angular acceleration is zero, but angular velocity is NOT constant, because axis of rotation can continually change direction.

Physics systems do not consider angular velocity as a primary quantity in simulations since it is not constant.  Since angular momentum is constant (law of conservation of momentum), it is the primary quantity and velocity can be derived from it.

Angular momentum and Linear momentum are 3-element vectors.


> Linear Momentum
> \\[ \vec{p}(t) = m \vec{v}(t) \\]
>
> Where:
> * \\(\vec{p}\\) is linear momentum.
> * \\(m\\) is mass.
> * \\(\vec{v}\\) is linear velocity.


> Angular Momentum
> \\[ \vec{L}(t) = I \vec{\omega}(t) \\]
>
> Where:
> * \\(\vec{L}\\) is angular momentum.
> * \\(I\\) is moment of inertia (the `inertia tensor`).
> * \\(\vec{\omega}\\) is angular velocity.

Torque can be calculated as the cross product between the "radial position vector of the point of force application" and the force vector itself.  In other words, a position vector extending out from the fulcrum to the position where a force is being applied to a lever cross multiplied against the size of the force.

However! Since angular velocity is not conserved, physics simulations typically express this in terms of angular momentum.

> \\[\begin{align}
>     \vec{N} &= \vec{r} \cross \vec{F} \\\\
>       &= I \alpha(t) \\\\
>       &= I \frac{d \omega(t)}{dt} \\\\
>       &= \frac{d}{dt} \left(I \omega(t)\right) \\\\
>       &= \frac{d \vec{L}(t)}{dt}
> \end{align}\\]
>
> Where:
> * \\(\vec{N}\\) is torque.
> * \\(\vec{r}\\) is the position vector along a lever indicating where a force is being applied.
> * \\(\vec{F}\\) is force applied to a lever to create torque.
> * \\(\alpha(t)\\) is angular acceleration.  Torque is proportional to moment of inertia and angular acceleration, just as Force is proportional to mass and linear acceleration.


### Solving equations of angular motion

Solving equations of angular motion are meant to find an object's orientation given some time \\(t\\).

You cannot solve equations of angular motion the same way as linear motion: using the first- and second-order derivatives to find velocity and acceleration, respectively and using verlet integration or explicit euler to find the position at some given time \\(t\\).

Instead, you'll want to solve directly for angular momentum \\(\vec{L}\\) instead of angular velocity \\(\vec{\omega}\\).
* Once you have this quantity, you can then calculate angular velocity using \\(I\\) and \\(\vec{L}\\).

In addition, angular velocity has three elements whereas orientation is a quaternion with four elements.  You have to convert angular velocity into quaternion form, then apply a special euqation that relates the orientation quaternion to the angular velocity quaternion.

See section 13.4.6.5 of the Game Engine Architecture for more details.
