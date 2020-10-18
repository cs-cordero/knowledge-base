# Matrix Transformations
In order to transform a set of vectors from one coordinate space to another, we can perform _linear transformations_ (scales, translations, and rotations) among different Cartesian coordinate frames.

## Coordinate Systems
A coordinate system \\( C \\) consists of an origin and three coordinate axes.  Points have coordinates \\( \langle x, y, z \rangle \\).  You can think of a point's coordinates as the distance to travel along each coordinate axis from the origin to reach the point.

## Linear Transformations
If you have a \\( C \\), you could also have \\( C' \\), which is a second coordinate system with coordinates \\( \langle x', y', z' \rangle \\) that _can be expressed as linear functions of coordinates \\( \langle x, y, z \rangle \\) in \\( C \\).

\\[ x'(x, y, z) = U_1 x + V_1 y + W_1 z + T_1 \\]
\\[ y'(x, y, z) = U_2 x + V_2 y + W_2 z + T_2 \\]
\\[ z'(x, y, z) = U_3 x + V_3 y + W_3 z + T_3 \\]

The above is a _linear transformation_ from \\( C \\) to \\( C' \\) and can be written in matrix form:

\\[
    \begin{bmatrix} x' \\\\ y' \\\\ z' \end{bmatrix} =
        \begin{bmatrix} U_1 & V_1 & W_1 \\\\ U_2 & V_2 & W_2 \\\\ U_3 & V_3 & W_3 \end{bmatrix}
        \begin{bmatrix} x \\\\ y \\\\ z \end{bmatrix}
        + \begin{bmatrix} T_1 \\\\ T_2 \\\\ T_3 \end{bmatrix}
\\]

The coordinates \\( \langle x', y', z' \rangle \\) is the distance to travel along each coordinate axis in \\( C' \\) to reach the same point \\( P \\) which in \\( C \\) is \\( \langle x, y, z \rangle \\).

Column vector \\( \vec{T} \\) is the translation from the origin of \\( C \\) to \\( C' \\).

The matrix with vectors \\( \vec{U} \\), \\( \vec{V} \\), \\( \vec{W} \\) represents how the orientation of the coordinate axes changes when transforming from \\( C \\) to \\( C' \\).

All four vectors \\( \vec{T} \\), \\( \vec{U} \\), \\( \vec{V} \\), \\( \vec{W} \\) can be combined into a 4x4 matrix.

If a _linear transformation_ can be inverted, it would look like this:

\\[
    \begin{bmatrix} x \\\\ y \\\\ z \end{bmatrix} =
        \begin{bmatrix} U_1 & V_1 & W_1 \\\\ U_2 & V_2 & W_2 \\\\ U_3 & V_3 & W_3 \end{bmatrix}^{-1}
        \left\(
            \begin{bmatrix} x' \\\\ y' \\\\ z' \end{bmatrix}
            - \begin{bmatrix} T_1 \\\\ T_2 \\\\ T_3 \end{bmatrix}
        \right\)
\\]

## Transforming with Orthogonal Matrices
When an orthogonal matrix transforms a vertex, it preserves lengths and angles.

\\[ \lVert MP \rVert = \lVert P \rVert \\]
\\[ \left\( M P_1 \right\) \cdot \left\( M P_2 \right\) = P_1 \cdot P_2 \\]

Orthogonal matrices therefore preserve the overall structure of a coordinate system as it transforms vertices to another coordinate system.  They can only represent either rotations or reflections.

A _reflection transform_ occurs when points are mirrored in a certain direction.

> **Reflects z coordinates of a point across the x-y plane**
>
> \\[ \begin{bmatrix} 1 & 0 & 0 \\\\ 0 & 1 & 0 \\\\ 0 & 0 & -1 \end{bmatrix} \\]

## Transform Types

### Scaling
To scale \\( \vec{P} \\), we just multiply it by a scalar \\( a \\).

##### Uniform scaling:

\\[ \vec{P'} = \begin{bmatrix} a & 0 & 0 \\\\ 0 & a & 0 \\\\ 0 & 0 & a \end{bmatrix} \begin{bmatrix} P_x \\\\ P_y \\\\ P_z \end{bmatrix} \\]

##### Non-uniform scaling:

\\[ \vec{P'} = \begin{bmatrix} a & 0 & 0 \\\\ 0 & b & 0 \\\\ 0 & 0 & c \end{bmatrix} \begin{bmatrix} P_x \\\\ P_y \\\\ P_z \end{bmatrix} \\]

##### Scaling applied in arbitrary axes:
Suppose you want to scale \\( \vec{P} \\) by factor \\( a \\) along axis \\( \vec{U} \\), by factor \\( b \\) along axis \\( \vec{V} \\), and by factor \\( c \\) along axis \\( \vec{W} \\)

\\[
    \vec{P'} =
        \begin{bmatrix} U_x & V_x & W_x \\\\ U_y & V_y & W_y \\\\ U_z & V_z & W_z \end{bmatrix}
        \begin{bmatrix} a & 0 & 0 \\\\ 0 & b & 0 \\\\ 0 & 0 & c \end{bmatrix}
        \begin{bmatrix} U_x & V_x & W_x \\\\ U_y & V_y & W_y \\\\ U_z & V_z & W_z \end{bmatrix}^{-1}
        \begin{bmatrix} P_x \\\\ P_y \\\\ P_z \end{bmatrix}
\\]


### Rotation
Given an angle \\( \theta \\) and an axis to rotate around, you can determine a 3x3 matrix that represents the rotation.

\\[
    \vec{R}_x(\theta) = \begin{bmatrix}
        1 & 0 & 0 \\\\
        0 & cos \theta & -sin \theta \\\\
        0 & sin \theta & cos \theta
    \end{bmatrix}
\\]
\\[
    \vec{R}_y(\theta) = \begin{bmatrix}
        cos \theta & 0 & sin \theta \\\\
        0 & 1 & 0 \\\\
        -sin \theta & 0 & cos \theta
    \end{bmatrix}
\\]
\\[
    \vec{R}_z(\theta) = \begin{bmatrix}
        cos \theta & -sin \theta & 0 \\\\
        sin \theta & cos \theta & 0 \\\\
        0 & 0 & 1
    \end{bmatrix}
\\]

##### Rotation applied to arbitrary axis:
_A_ is the arbitrary axis around which to rotate.

\\[
    \vec{R}_A(\theta) = \begin{bmatrix}
        c + (1-c) A_x^2 & (1-c) A_x A_y - s A_z & (1-c) A_x A_z + s A_y \\\\
        (1-c) A_x A_y + s A_z & c + (1-c) A_y^2 & (1-c) A_y A_z - s A_x \\\\
        (1-c) A_x A_z - s A_y & (1-c) A_y A_z + s A_x & c + (1-c) A_z^2
    \end{bmatrix}
\\]
where \\( c = cos \theta \\) and \\( s = sin \theta \\)

## Homogenous Coordinates
Without utilizing 4D coordinates (and thereby homogenous coordinates), in order to both rotate/scale _and_ translate a vector, we'd have to do something like this:

\\[ \vec{P'} = M \vec{P} + \vec{T} \\]

A 3D vector can be turned into a 4D _homogenous coordinates_ by setting its fourth component \\( w \\) to 1 or 0.  You would use 1 if the vector is a _point_, meaning that it indicates an actual position in 3D space. You would use 0 if the vector is a _direction_, meaning translations should have no effect..

\\[
    F = \left\[
        \begin{array}{ccc|c}
            U_x & V_x & W_x & T_x \\\\
            U_y & V_y & W_y & T_y \\\\
            U_z & V_z & W_z & T_z \\\\
            \hline
            0 & 0 & 0 & 1
        \end{array}
    \right\]
\\]


To convert a _point_ from its homogenous coordinates back into its 3D vector.

\\[ \vec{P'} = \langle \frac{x}{w}, \frac{y}{w}, \frac{z}{w} \rangle \\]

## Normal Vectors
You have to be careful when transforming a normal vector.
* Normals should be unaffected by translations.
* When a _nonorthogonal_ matrix transforms a normal vector, it may result in a direction that is no longer perpendicular to the surface.
