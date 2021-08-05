# Collision Detection Systems

The purpose of a collision detection system is to determine whether any objects in the game world have come into *contact*.

Each logical object is represented by one or more geometric *shapes*, which are usually simple, e.g., spheres, boxes, capsules, etc, but may be more complex.

The collision detection determines if any of the geometric shapes are *intersecting* at any time.

The collision detection system must also provide relevant information about the _nature_ of each contact.
* Collisions can look for interpenetrations of two objects so that they do not intersect on the frame.
* Collisions can feed into the physics system to allow things to come to rest, e.g., a human character standing on the ground is colliding with the ground, which is resisting the force of gravity to make the character appear "at rest".
* Collisions can also trigger an event, i.e., when a missile comes in contact with something, it explodes or when a player collides with a health globe, it consumes the health globe and gives the player some HP.

### Collidable Entities

If an object needs to be capable of colliding with other objects that are also capable of colliding, we need to provide it with a _collision representation_ which is distinct (but probably related) to that object's actual shape, position, orientation, gameplay representation, and mesh.

Commercial physics engines may often call its collidable entities as `collidable` or `actor`s.  These collidable pieces of information contains a `shape` and a `transform`.

The transforms are used for the following:
1. To describe the object's `size` and the shape's `orientation` relative to the coordinate axis.
1. To locate teh object in the game world inexpensively (find its `position`).
1. Making it distinct from the `shape` is useful because the `shape` could be overloaded beyond simple `box`, `sphere`, etc. to be `car`, `chair`, etc.

Game objects may have zero or more collidables.  Usually you see zero or one for simple objects.  Complex objects will require multiple.


### Collision World

All collidables need to be able to be referenced by the collision detection system.

Maintaining collision information in a private data structure has some advantages over storing the representation in the game objects themselves.
* Since the system only holds data for collidables, it avoids iterating over non-colliding objects.
* Permits collision data to be organizd in the most efficient manner possible. For example, it can take advantage of cache coherency.
* Encapsulation


### Physics World

A physics world is usually tightly integrated with the collision system to the point that they might actually be sharing its "world" data structure with the collision world.

Each `rigid body` in the physics world is usually associated with a single collidable in the collision system. Not all collidables need to be rigid bodies.  For example, if something is collidable but not a Rigid Body, then it tells the system that this object is always fixed in space (like a wall).

It can be typical for the Physics world to be the `controller` of the Collision world, and it may actually be the one that calls the collision world's API to perform its duties for each physics simulation time step.


### Shapes

In 2D, the collision shapes are made up of polygons that define an `inside` and an `outside`.

In 3D, collision shapes are made up of multiple polygons (a polyhedron) that similarly define an `inside` and an `outside`).

Sometimes in 3D, a collision shape may take the shape of a surface that has a `front` and a `back`, but no `inside` or `outside`.  Surfaces can sometimes be given an `extrusion` parameter that effectively turns it into an actual shape with thickness.

Two shapes are intersecting if any points within either shape are overlapping.

When two shapes are in contact, the collision system should package the contact information into a data structure that is instantiated for every contact detected.
* This contact data structure often includes a `separating vector`, which is a vector along which we can slide the objects to move them out of collision.
* Contains informationa bout which two collidables were in contact, including which individual shapes were intersecting.
* May also include velocity of the bodies projected onto the separating vector normal.

Convex shapes are easier to calculate intersections than concave shapes.
* If you can draw a straight line originating from inside the shape that passes through its surface multiple times, it is `concave`.
* If it can only pass through the surface once, then it is `convex`.
* Circles, rectangles, triangles are all convex, but Pac-Man is not.


#### Collision Primitives
1. Spheres
    1. Spheres are the simplest 3D dimensional volume containing only a center point and radius.  This information can be packed in a 4D vector, which works well with SIMD math libraries.
1. Capsules
    1. The next simplest volume is a pill-shape, composed of a cylinder and two hemispherical end caps.  This is represented with two points and a single radius.
    1. It is more efficient to calculate intersections on these capsules than cylinders or boxes.
1. Axis-Aligned Bounding Box (AABB)
    1. A rectangular volume whose faces are parallel to the axis of the coordinate system.
    1. It is defined by two points representing opposite corners of the box.  These corners should be the minimum coordinates and the maximum coordinates relative to the coordinate system in which it is defined.
    1. Has fast intersection calculations but has the big limitation that it must be axis aligned.
1. Oriented Bounding Box (OBB)
    1. An AABB that is allowed to rotate relative to its coordinate system.
    1. Often represented by three half-dimensions (half-width, half-depth, half-height), and a transform that positions the center of the box and defines its orientation relative to the coordinate axis.
    1. They do a better job at fitting arbitrarily oriented objects but the representation is still simple.
1. Discrete Oriented Polytopes (DOP)
    1. A more-general case of the AABB and OBB.  It is a convex polytope that approximates teh shape of an object.
    1. DOPs take a number of planes at infinity and slides them along their normal vectors until they come into contact with the object whose shape is being approximated.
    1. AABBs and OBBs are therefore a 6-DOP, but you can theoretically construct a k-DOP for any object.
1. Arbitrary Convex Volumes
    1. Usually requires an offline tool to help create and verify that the object is indeed convex.
    1. Way more expensive to calculate intersections with these volumes but there exist some helpful algorithms to do so as long as it remains convex, like "GJK".
1. Poly Soup
    1. A collection of polygons that need not be convex.
    1. Most expensive to calculate intersections.
    1. May or may not represent a volume, it could represent an open surface.
    1. You can carefully use winding order to make sure the poly soup as a "front" and a "back". Or if your poly soup is special, like if it represents terrain in your game, you can just declare which side of it is front (i.e., the side that isn't facing underground)
1. Compound Shapes
    1. A collection of the above shapes.  For example a chair might have two boxes, one for the base and seat, and a second for the chair back.
    1. As an optimization:  You might define bigger convex bounding volume containing all of the shapes as a parent shape, perform collision tests against _that_, and if you detect a collision, then detect the sub shapes for a detection.


### Collision Testing

See [https://en.wikipedia.org/wiki/Analytic_geometry](https://en.wikipedia.org/wiki/Analytic_geometry).

#### Point vs Sphere

* A point \\(p\\) lies within a sphere if the separation vector \\(s\\) between the point and the sphere's center \\(c\\) is equal to or less than the sphere's radius \\(r\\).

> \\[s = c - p\\]
> 
> if \\(\left|s\right| \le r\\), then \\(p\\) is inside the sphere.

#### Sphere vs Sphere

* Two spheres are intersecting if the separation vector of their center points are less than or equal to the sum of their radii.

> \\[s = c_1 - c_2\\]
>
> if \\(\left|s\right| \le \left(r_1 + r_2\right)\\), then the spheres intersect.

Avoiding the square root operation:

> \\[s = c_1 - c_2\\]
>
> \\[\left|s\right|^2 = s \cdot s\\]
>
> if \\(\left|s\right|^2 \le \left(r_1 + r_2\right)^2\\), then the spheres intersect.


#### The Separating Axis Theorem

See [http://en.wikipedia.org/wiki/Separating_axis_theorem](http://en.wikipedia.org/wiki/Separating_axis_theorem).

If an axis can be found along which the _projections_ of two _convex_ shapes do not overlap, then we can be certain that the two shapes do not intersect at all.

If such an axis does not exist _and_ the shapes are convex, thenw e know for certain that they do intersect.

The projection looks like a shadow cast from the object onto a thin line.  In 3D, the line is a separating plane, but the separating axis is still an axis (an infinite line).

The projection of a 3D convex shape onto an axis is a line segment, represented by the closed interval \\(\left[c_{\text{min}}, c_{\text{max}}\right]\\).

Some types of shapes have properties that make the potential separating axes obvious.  The idea is to project the sahpes onto each potential separating axis in turn then check whether or not the two projection intervals,  \\(\left[c_{\text{min}}^A, c_{\text{max}}^A\right]\\) and \\(\left[c_{\text{min}}^B, c_{\text{max}}^B\right]\\) are disjoint for every axis.


#### AABB vs AABB

AABBs are one of the above mentioned "shapes [which] have properties that make the potential separating axes obvious".

Since both objects are aligned to the same three axes, the separating axes will exist along one of these three axes.

To test if two AABB objects intersect, we can check the min and the max of each object projected along each axes independently.  If _all three axes_ oberlap, then the two AABBs are intersecting, otherwise they are not.


#### The GJK Algorithm

Applies _only_ to CONVEX shapes. Once any shape is concave, this won't work anymore.

See:
* Original paper: [https://ieeexplore.ieee.org/xpl/freeabs_all.jsp?&arnumber=2083](https://ieeexplore.ieee.org/xpl/freeabs_all.jsp?&arnumber=2083)
* SIGGRAPH PowerPoint: [https://realtimecollisiondetection.net/pubs/SIGGRAPH04_Ericson_the_GJK_algorithm.ppt](https://realtimecollisiondetection.net/pubs/SIGGRAPH04_Ericson_the_GJK_algorithm.ppt)
* Another PowerPoint: [https://www.laas.fr/~nic/MOVIE/Workshop/Slides/Gino.vander.Bergen.ppt](www.laas.fr/~nic/MOVIE/Workshop/Slides/Gino.vander.Bergen.ppt)
* **Casey Muratori's Video**: [https://mollyrocket.com/849](https://mollyrocket.com/849)


The GJK algorithm relies on a geometric operation known as the _Minkowski Difference_:
* Take every point that lies within shape B and subtract it, pairwise, from every point inside shape A.
* You now have a resulting Set of points \\(\left\\{\left(A_i - B_j\right)\right\\}\\).  This is called the `Minkowski Difference`.
* The `Minkowski difference` _contains the origin_ if and only if the two shapes intersect. This would be true because if two points overlap/intersect, their difference would be zero.
* The `Minkowski difference` of two convex shapes is itself a convex shape and all we care about is the _convex hull_ of the Minkowski difference, not the interior points.
* We need to find the `tetrahedron` (a four sided shape made of triangles) that lies on the convex hull.
* GJK is an iterative algorithm that starts with a one-point shape lying anywhere within the Minkowski difference hull, then it tries to build higher-order shapes that mght contain the origin.


#### Collisions with Moving Bodies

The positions of objects are not continuous, they are actually calculated in discrete timesteps.

When small and fast moving bodies move, they might move at a speed faster that the size of its own pixels on screen.  If the collision system calculates collisions only at these discrete timesteps, there could be a "tunneling" bug where objects move so fast past another object that "should" have collided, but didn't.

You can avoid tunneling using `swept shapes`, which is the shape extruded along its motion path from beginning to end.  A sphere moving becomes a capsule.  A triangle moving becomes a tirangular prism.

This is effectively LERP, which means that it falls short when the object is moving along a curved path. However:
* A convex shape extruded along a curved path creates a new shape that is not necessarily convex.
* A convex shape that is actively rotating does not necessarily create a convex swept shape either.

Because of the above, it can be very expensive to to calculate intersections for these moving objects using swept shapes.

An alternative approach is called `Continuous Collision Detection` (CCD).  The goal is to find the earliest `Time of Impact` (TOI) between two moving objects over a given time interval.

This approach basically defines the beginning of the timestep and the end of the timestep then tries to locate the TOI along the timestep using a number of different search algorithms.


#### Optimizations

Collision detection systems require spatial hashing, spatial subdivision, or hierarchical bounding volumes in order to redue gthe number of intersection tests that must be performed.

* `Temporal coherency`, aka `frame-to-frame coherency` takes advantage of the fact that positions and orientations are usually quite similar from time step to time step. We could cache results across multiple time steps.
* `Spatial Partitioning` greatly reduces teh number of collidables to check by dividing the world space into a number of smaller regions.  If we can determine that a pair of collidables do not occupy the same region then we don't need to perform intersection tests on them.
    * This can be done with octrees, binary space partitioning trees, kd-trees, sphere trees, etc.
* A phased approach: `broad`, `mid`, `narrow`.
    * First, gross AABB tests are performed to determine which collidables are potentially intersecting.
        * A common algorithm for this is called the `Sweep and Prune`, see [https://en.wikipedia.org/wiki/Sweep_and_prune](https://en.wikipedia.org/wiki/Sweep_and_prune)
        * Sort the minimum and maximum dimensions of the collidables' AABBs along the three principal axes, then check for overlapping AABBs by traversing the sorted lists.
    * Second, the bounding volumes of compound shapes are tested.
    * Finally, the collidables' individual primitives are tested.


