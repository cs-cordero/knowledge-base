# Matrix Transformations

In order to transform a set of vectors from one coordinate space to another, we can perform _linear transformations_ (scales, translations, and rotations) among different Cartesian coordinate frames.

See:
* [https://docs.microsoft.com/en-us/windows/win32/direct3d9/transforms](https://docs.microsoft.com/en-us/windows/win32/direct3d9/transforms)
* [https://gamedev.stackexchange.com/questions/57474/tbn-matrix-eye-vs-world-space-conflict](https://gamedev.stackexchange.com/questions/57474/tbn-matrix-eye-vs-world-space-conflict)
* [https://www.evl.uic.edu/ralph/508S98/coordinates.html](https://www.evl.uic.edu/ralph/508S98/coordinates.html)
* [https://stackoverflow.com/questions/19747082/how-does-coordinate-system-handedness-relate-to-rotation-direction-and-vertices](https://stackoverflow.com/questions/19747082/how-does-coordinate-system-handedness-relate-to-rotation-direction-and-vertices)
* [http://www.f-lohmueller.de/pov_tut/a_geo/a_geo85e.htm](http://www.f-lohmueller.de/pov_tut/a_geo/a_geo85e.htm)
* [https://www.reddit.com/r/gameenginedevs/comments/jd6oz0/very_confused_about_lefthanded_vs_righthanded/](https://www.reddit.com/r/gameenginedevs/comments/jd6oz0/very_confused_about_lefthanded_vs_righthanded/)

## Handedness
A left-handed matrix transform has the following shape:
\\[
    \begin{bmatrix}
        U_x & U_y & U_z & 0 \\\\
        V_x & V_y & V_z & 0 \\\\
        W_x & W_y & W_z & 0 \\\\
        T_x & T_y & T_z & 1
    \end{bmatrix}
\\]

Whereas a right-handed matrix transform has the following shape:
\\[
    \begin{bmatrix}
        U_x & V_x & W_x & T_x \\\\
        U_y & V_y & W_y & T_y \\\\
        U_z & V_z & W_z & T_z \\\\
        0 & 0 & 0 & 1
    \end{bmatrix}
\\]

In the above matrices, the vectors \\(\vec{U}\\), \\(\vec{V}\\), \\(\vec{W}\\) represent the basis vectors in the resulting coordinate system as it appears to the source coordinate system.  Together they constitute how the vector is to be _rotated_.

The vector \\(\vec{T}\\) represents a _translation_.

### How to apply matrix transforms to a vector
Order matters when transforming a vector using a matrix because the operation is not commutative.

In other words:  \\(\vec{V} \times M \ne M \times \vec{V}\\)

**WHEN THE TRANSFORM MATRIX IS LEFT-HANDED, THE VECTOR GOES ON THE LEFT SIDE**
\\[\vec{V'} = \vec{V} \times M_{LH}\\]

**WHEN THE TRANSFORM MATRIX IS RIGHT-HANDED, THE VECTOR GOES ON THE RIGHT SIDE**
\\[\vec{V'} = M_{RH} \times \vec{V}\\]

## Coordinate Systems
A coordinate system \\( C \\) consists of an origin and three coordinate axes.  Points have coordinates \\( \langle x, y, z \rangle \\).  You can think of a point's coordinates as the distance to travel along each coordinate axis from the origin to reach the point.

A transformation matrix converts vectors from a _source_ space \\( A \\) to _target_ space \\( B \\).  As explained above and below, the \\(\vec{U}\\), \\(\vec{V}\\), \\(\vec{W}\\) vectors represent the basis vectors of space \\(B\\) as it appears when viewing them from space \\(A\\).

You can construct any such transformation matrix on your own; the coordinate space that the \\(\vec{U}\\), \\(\vec{V}\\), \\(\vec{W}\\) vectors are defined in dictate what target space the transformation matrix transforms vectors into.

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

#### Rotations depend on the handedness of your coordinate system!
The above formulas assume a _right-handed_ coordinate system.

The following are the **left-handed equivalents**:

\\[
    \vec{R}_x(\theta) = \begin{bmatrix}
        1 & 0 & 0 \\\\
        0 & cos \theta & sin \theta \\\\
        0 & -sin \theta & cos \theta
    \end{bmatrix}
\\]
\\[
    \vec{R}_y(\theta) = \begin{bmatrix}
        cos \theta & 0 & -sin \theta \\\\
        0 & 1 & 0 \\\\
        sin \theta & 0 & cos \theta
    \end{bmatrix}
\\]
\\[
    \vec{R}_z(\theta) = \begin{bmatrix}
        cos \theta & sin \theta & 0 \\\\
        -sin \theta & cos \theta & 0 \\\\
        0 & 0 & 1
    \end{bmatrix}
\\]


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


## Matrix Concatenation
Matrix concatenation goes from left to right.

Given a transformation matrix \\(A\\) and a transformation matrix \\(B\\):

\\(AB\\) results in a transformation matrix that encodes the combined effect of first applying matrix A to a vector, followed by applying matrix B.

\\(BA\\) has the opposite effect: it encodes the effect of applying matrix B, followed by applying matrix A.

And of course, since matrix multiplication is **not commutative**, \\(AB \ne BA \\).

> **Example**
>
> _Given:_
>
> Matrix A is a 90 degree rotation about the y-axis (left-handed).
> \\[A = \begin{bmatrix}
>   0 & 0 & -1 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   1 & 0 & 0 & 0 \\\\
>   0 & 0 & 0 & 1
> \end{bmatrix}\\]
>
> Matrix B is a translation (left-handed).
>
> \\[B = \begin{bmatrix}
>   1 & 0 & 0 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   0 & 0 & 1 & 0 \\\\
>   3 & 4 & 5 & 1
> \end{bmatrix}\\]
>
> Therefore:
> \\[AB = \begin{bmatrix}
>   0 & 0 & -1 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   1 & 0 & 0 & 0 \\\\
>   0 & 0 & 0 & 1
> \end{bmatrix}
> \begin{bmatrix}
>   1 & 0 & 0 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   0 & 0 & 1 & 0 \\\\
>   3 & 4 & 5 & 1
> \end{bmatrix}
> = \begin{bmatrix}
>   0 & 0 & -1 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   1 & 0 & 0 & 0 \\\\
>   3 & 4 & 5 & 1
> \end{bmatrix}
>\\]
>
> \\[BA = \begin{bmatrix}
>   1 & 0 & 0 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   0 & 0 & 1 & 0 \\\\
>   3 & 4 & 5 & 1
> \end{bmatrix}
> \begin{bmatrix}
>   0 & 0 & -1 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   1 & 0 & 0 & 0 \\\\
>   0 & 0 & 0 & 1
> \end{bmatrix}
> = \begin{bmatrix}
>   0 & 0 & -1 & 0 \\\\
>   0 & 1 & 0 & 0 \\\\
>   1 & 0 & 0 & 0 \\\\
>   5 & 4 & -3 & 1
> \end{bmatrix}
>\\]
