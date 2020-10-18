# Quaternions
Quaternions can be used to represent rotations.

* Require less memory
* Concatenating quaternions require less arithmetic
* More easily interpolated

They are represented as a 4D vector.

The 4th component is a scalar value, taking the space for \\( w \\).

\\[ q = s + \vec{v} = \langle w, x, y, z \rangle \\]

Alternative representation (_Grimoire_ uses this notation).  This notation makes it look like a vector in homogenous coordinates.

\\[ q = \langle x, y, z, w \rangle \\]

### Creating a quaternion from an angle and axis of rotation

\\[ q = cos \frac{\theta}{2} + \vec{A} sin \frac{\theta}{2} \\]

where \\( \theta \\) is an angle about the unit axis \\( A \\).

### Multiplying Quaternions
Multiplication is NOT commutative, so order really matters.

\\[ q_1 q_2 = s_1 s_2 - \vec{v_1} \cdot \vec{v_2} + s_1 \vec{v_2} + s_2 \vec{v_1} + \vec{v_1} \times \vec{v_2} \\]

### Rotating Vectors with Quaternions
Suppose some function \\( \phi \\) represents a rotation meant to be applied to some point \\( \vec{P} \\).  To be a rotation it must:
* Preserve lengths
* Preserve angles
* Preserve handedness

Length is preserved if:

\\[ \lVert \phi(\vec{P}) \rVert = \lVert \vec{P} \rVert \\]

Angle is preserved if:

\\[ \phi(\vec{P_1}) \cdot \phi(\vec{P_2}) = \vec{P_1} \cdot \vec{P_2} \\]

Handed is preserved if:

\\[ \phi(\vec{P_1}) \times \phi(\vec{P_2}) = \phi(\vec{P_1} \times \vec{P_2}) \\]

This is how you do the above with a quaternion:

\\[ \vec{P'} = q P q^{-1} \\]

which is equivalent to:

\\[ R_q =
    \begin{bmatrix}
        1-2y^2 - 2 z^2 & 2xy-2wz & 2xz+2wy \\\\
        2xy+2wz & 1-2x^2-2z^2 & 2yz-2wx \\\\
        2xz-2wy & 2yz+2wx & 1-2x^2-2y^2
    \end{bmatrix}
\\]

### Spherical Linear Interpolation
\\[
    q(t) = \frac{sin \theta (1-t)}{sin \theta} q_1 + \frac{sin \theta t}{sin \theta} q_2
\\]
where \\( 0 \le t \le 1 \\)
