# Skinning
The process of attaching the vertices of a 3D mesh to a posed skeleton is known as "Skinning".

Each vertex can be _bound_ to one or more joints.
    
The vertex's positions is a _weighted average_ of the positions it would have assumed if it had been bound to each joint independently.

At each vertex, you ned to have the following information:
* The index or indices of the `Joint`s to which it is bound,
* The weighting factor describing how much influence that joint should have on the final vertex position.

```rust
struct SkinnedVertex {
    position: Vector3,
    normal: Vector3,
    texture_coordinates: Vector2,
    joint_indices: [u8; 4], // max of 4 joints
    joint_weight: [u8; 3], // you don't need 4 weights since the last can be calculated on the fly.
}
```

### Tracking mesh vertices to joints

A `skinning matrix` is a matrix that can transform the vertices of a mesh __from bind pose__ into new positions that correspond to the current pose of the skeleton.

The position of a skinned vertex is specified in model space, like all mesh vertices.

__Unlike other matrix transforms, a skinning matrix is NOT a change of basis transform__: it goes from model space (bind pose) to model space (actual pose)

Given the bind pose of the joint \\(j\\) in model space, \\(B_{j \rightarrow M}\\), this matrix transforms a point whose coordinates expressed in \\(j\\)'s space into an equivalent set of model-space coordinates.

Then, given a vertex whose coordinates are expressed in model-space, if you want to express it in joint-space, you can do so with the _inverse_ of the above bind pose matrix.

\\[ \vec{v_j} = \vec{v_M^B} B_{M \rightarrow j} = \vec{v_M^B} \left( B_{j \rightarrow M} \right)^{-1} \\]

Given a joint's _current pose_, similar to the bind pose matrix, it defines vertices in joint space in model space, i.e., \\(C_{j \rightarrow M}\\).

> \\[
>     \begin{align}
>         \vec{v_M^C} &= v_j C_{j \rightarrow M} \\\\
>                     &= \vec{v_M^B} \left( B_{j \rightarrow M} > \right)^{-1} C_{j \rightarrow M} \\\\
>                     &= \vec{v_M^B} K_j
>     \end{align}
> \\]
>
> Where
> * \\(K_j = \vec{v_M^B} \left( B_{j \rightarrow M} > \right)^{-1} C_{j \rightarrow M} \\)
> * This \\(K_j\\) is known as the __skinning matrix__.

When you have multiple joints, it can be useful to create an array of skinning matrices \\(K_j\\) for every joint.

\\(B_{j \rightarrow M}\\) matrices never change so can be calculated once per vertex.  The current poses \\(C_{j \rightarrow M}\\) change on each frame and will therefore need to be calculated on the fly.

Don't forget that a single matrix from joint space to model space represents a _global pose_, meaning for a given joint, you have to walk up its local pose matrices to the root joint to create either \\(B_{j \rightarrow M}\\) or \\(C_{j \rightarrow M}\\).

### When multiple joints per vertex are involved
Calculate a new vector for each joint individually, then average all the vectors together.

> \\[ \vec{v_M^C} = \sum_{i=0}^{N-1} w_i \vec{v_M^B} K_{ji} \\]
>
> Where
> * \\(N\\) is the number of joints associated with vertex \\(\vec{v}\\).
> * \\(w_i\\) is the weighting factor of joint \\(i\\).
> * \\(K_{ji}\\) is the skinning matrix for joint \\(j_i\\).
