# Collision Queries

The collision system must answer other questions about the collidables beyond "are these two collidables intersecting"?

* If a bullet travels from the player's weapon in a given direction, what is the first target it will hit, if any?
* Can a vehicle move from point A to point B without striking anything along the way?
* Find all enemy objects within a given radius of a character.

These are all synonyms:
\\[\text{collision cast} = \text{cast} = \text{trace} = \text{probe}\\]

### Ray Cast

This is a misnomer, because we actually only cast a directed line segment, which has \\(p_0\\) and \\(p_1\\): a beginning and an end.

The directed line segment is tested against collidable objects in the `Collision World`, then returns contact point(s).

The ray cast is usually described as a 3D vector to indicate the starting point, followed by a 3D directional vector with a length equal to the length of the line segment, so that when these vectors are added together, they equal the end point.

\\[\vec{p}(t) = \vec{p}_0 + t\\,\vec{d}, \quad t \in \left[0, 1\right]\\]

Most game collision systems can find the _earliest contact point_, and it's usually returned as a value of `t`.

```rust
struct RayCastContact {
    t_value: f32,
    collidableId: u32,
    normal: Vector3 // surface normal at contact point
}
```

Ray casts are useful for:
* Finding out whether two objects have a direct line-of-sight to each other.
* Drawing weapon systems to determine if some bullet or strike hits another object.
* AI systems (for line of sight, targeting, movement, etc.)
* Vehicle systems (for snapping to a terrain)


### Shape Casting

Instead of a ray, it's also common to cast a _convex_ shape.  It's still described with a \\(\vec{p}_0\\) and a distance to travel \\(\vec{d}\\), but now has type, dimensions and orientation of the shape to cast.

At any point \\(t\\), including the starting point, there are two states:
1. The cast shape is already interpenetrating at least one other collidable, which prevents it from moving forward.
1. The cast shape is not interprenetrating anything and so it can move forward along \\(\vec{d}\\).

It is possible for the shape to come in contact with or intersect multiple contact points. If it wasn't intersecting anything at its starting point, then the contact points should only be on the surface of the cast shape.  Otherwise, the contact points _could_ have many contact points inside the shape.

For shape casts, the returned information usually includes the \\(t\\) value as normal, but would also need to return actual contact points on the surface.

```rust
fn cast_shape(...) -> Vec<ShapeCastContact> { ... }

struct ShapeCastContact {
    t_value: f32,
    collidable_id: u32,
    contact_point: Vector3,
    normal: Vector3,
}
```

Shape casts are useful for:
* Determine whether the camera is itself colliding with objects in the game world.
* Sphere or capsule casts are commonly used to implement character movement.


### Phantoms

It can be useful to have a collidable that can perform collision queries against all other collidables in the world, but it itself has no effect on those collidables.

These types of collidables are called Phantoms and they do not take part in the physics simulation either.


### Collision Filtering

As part of collision queries, you may want to control types of collidables that may collide with each other.

#### Collision Masking and Layers

Categorize all collidables and use a lookup table to determine whether certain categories may collide with one another or not.

#### Callbacks

Have the collision library invoke a callback function whenever a collision is detected.  This callback can inspect the collision and make the decision whether to allow or reject the collision.
