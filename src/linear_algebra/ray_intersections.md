# Ray vs Surface Intersection Calculations

For all equations below, assume the ray is defined as:

\\[ \vec{T}(t) = \vec{S} + t \vec{V} \\]

### Ray vs Triangle
A triangle is defined by three points \\(\vec{P_0}, \vec{P_1}, \vec{P_2}\\).

We need to find the plane that these points create.  A plane can be represented as a normal vector and a distance from the origin.

First, we get the normal.
\\[ \vec{N} = (\vec{P_1} - \vec{P_0}) \times (\vec{P_2} - \vec{P_0})\\]

Second, to get the signed distance, \\(d\\), we can take the negative dot product of \\(\vec{N}\\) and any arbitrary point in the plane, so we'll just pick \\(\vec{P_0}\\).

\\[ d = -\vec{N} \cdot \vec{P_0} \\]

Finally, the 4D plane vector is given as:

\\[ \vec{L} = \langle \vec{N}, d \rangle \\]

The value of \\(t\\) that corresponds to where the ray intersects this plane is given as:

\\[ t = -\frac{\vec{L} \cdot \vec{S}}{\vec{L} \cdot \vec{V}} \\]

If the denominator above is 0, then there is no intersection, otherwise you can plug this \\(t\\) back into the ray equation to get the intersection point, \\(\vec{P_{\text{intersection}}}\\).

But now you have to determine whether this intersection point **falls inside of the triangle**, and not just along the plane this triangle creates.

> \\[ \vec{R} = w_1 \vec{Q_1} + w_2 \vec{Q_2} \\]
>
> Where:
> \\[ \vec{R} = \vec{P_{\text{intersection}}} - \vec{P_0} \\]
> \\[ \vec{Q_1} = \vec{P_1} - \vec{P_0} \\]
> \\[ \vec{Q_2} = \vec{P_2} - \vec{P_0} \\]

Taking the dot product of both sides of the equation above by \\(\vec{Q_1}\\) and then \\(\vec{Q_2}\\) creates a system of equations that can help us solve for \\(w_1\\) and \\(w_2\\).

\\[
    \begin{bmatrix} w_1 \\\\ w_2 \end{bmatrix} =
    \begin{bmatrix}
        \vec{Q_1} \cdot \vec{Q_1} & \vec{Q_1} \cdot \vec{Q_2} \\\\
        \vec{Q_1} \cdot \vec{Q_2} & \vec{Q_2} \cdot \vec{Q_2} \\\\
    \end{bmatrix}^{-1}
    \begin{bmatrix}
        \vec{R} \cdot \vec{Q_1} \\\\ \vec{R} \cdot \vec{Q_2}
    \end{bmatrix}
\\]
\\[
    =
    \frac{1}{
        (
            (\vec{Q_1} \cdot \vec{Q_1})
            (\vec{Q_2} \cdot \vec{Q_2})
        ) -
        (\vec{Q_1} \cdot \vec{Q_2})^2
    }
    \begin{bmatrix}
        \vec{Q_2} \cdot \vec{Q_2} & -\vec{Q_1} \cdot \vec{Q_2} \\\\
        -\vec{Q_1} \cdot \vec{Q_2} & \vec{Q_1} \cdot \vec{Q_1} \\\\
    \end{bmatrix}
    \begin{bmatrix}
        \vec{R} \cdot \vec{Q_1} \\\\ \vec{R} \cdot \vec{Q_2}
    \end{bmatrix}
\\]

The point \\(\vec{R}\\) lies inside the triangle **iff** all three weights \\(w_0\\), \\(w_1\\), \\(w_2\\) are nonnegative.  Note that \\(w_0 = 1 - w_1 - w_2\\).


### Ray vs Box
A box is defined with six plane equations.
> \\[x = 0\\]
> \\[y = 0\\]
> \\[z = 0\\]
> \\[x = r_x\\]
> \\[y = r_y\\]
> \\[z = r_z\\]
>
> Where
> \\(r_x\\), \\(r_y\\), \\(r_z\\) are the dimensions of the box.

We need to consider _at most_ three planes to determine whether the ray intersects the box, since the other three planes would be facing _away_ from the ray's direction \\(\vec{V}\\).

We can do this with a little bit of logic, using each component of \\(\vec{V}\\) one-by-one.
* If \\(\vec{V_x} = 0\\) , then the ray cannot intersect the planes at \\(x = 0\\) and \\(x = r_x\\) since it is parallel to those planes.
* If \\(\vec{V_x} \gt 0\\), then the ray would intersect the plane at \\(x = 0\\) before the plane at \\(x = r_x\\), and therefore we'd only need to consider the first plane.
* Alternatively, if \\(\vec{V_x} \lt 0\\), then the ray would intersect the plane at \\(x = r_x\\) before the plane at \\(x = 0\\), and therefore we'd only need to consider the first plane.

This reduces the problem to at most three Ray vs Surface intersections for each component of the \\(\vec{V}\\).

The value of \\(t\\) which intersects the plane \\(x = r_x\\) is:
\\[ t = \frac{r_x - \vec{S_x}}{\vec{V_x}} \\]

Once we have the intersection point on the plane, we need to determine whether the point is _inside_ the face of the box along that plane, which is pretty easy.  Both of the following conditions must be true:

\\[ 0 \ge \vec{T(t)}_y \ge r_y \\]
\\[ 0 \ge \vec{T(t)}_z \ge r_z \\]


### Ray vs Sphere
A sphere of radius \\(r\\) is defined by this equation:
\\[ x^2 + y^2 + z^2 = r^2 \\]

Using the components of a ray in place of \\(x\\), \\(y\\), and \\(z\\):
\\[
    \left(\vec{S_x} + t \vec{V_x}\right)^2 +
    \left(\vec{S_y} + t \vec{V_y}\right)^2 +
    \left(\vec{S_z} + t \vec{V_z}\right)^2 =
    r^2
\\]

This equation expands to a quadratic polynomial:

\\[
    \left(\vec{V_x}^2 + \vec{V_y}^2 + \vec{V_z}^2\right) t^2
    + 2 \left(\vec{S_x}\vec{V_x} + \vec{S_y}\vec{V_y} + \vec{S_z}\vec{V_z}\right) t
    + \vec{S_x}^2 + \vec{S_y}^2 + \vec{S_z}^2 - r^2
    = 0
\\]

This might not look like a quadratic polynomial, but it is! It is in the form:

> \\[ a t^2 + bt + c = 0 \\]
>
> Where
> * \\(a = \vec{V}^2\\)
> * \\(b = 2 \left(\vec{S}\vec{V}\right)\\)
> * \\(c = \vec{S}^2 - r^2\\)

Since this is a quadratic polynomial, we can use the discriminant, \\(D = b^2 - 4ac\\)  to tell us whether the ray intersects the sphere at all.

* If \\(D \lt 0\\), it does not intersect the sphere.
* If \\(D = 0\\), it is tangential to the sphere.
* If \\(D \gt 0\\), it intersects the sphere at two points.

To find the intersection point closer to the ray's origin \\(\vec{S}\\), which corresponds to a smaller value of \\(t\\), it is given by:

\\[ t = \frac{-b - \sqrt{D}}{2a} \\]


### Ray vs Cylinder
Imagine a cylinder placed flat and centered on the origin, such that its flat bottom face is at \\(z = 0 \\).

The equations that define a cylinder is:

> \\[ x^2 + m^2 y^2 = r^2 \\]
> \\[ 0 \ge z \ge h \\]
>
> Where
> * The cylinder's height is \\(h\\).
> * \\(m = \frac{r}{s}\\)
> * \\(r\\) is the radius in the x direction.
> * \\(s\\) is the radius in the y direction.
> * When \\(r = s\\), the cylinder is circular and \\(m = 1\\).

Taking the above function, substituting the components of the ray, then expanding the exponent terms yields yet another quadratic polynomial:

\\[
    \left(\vec{V_x}^2 + m^2 \vec{V_y}^2\right) t^2
    + 2 \left(\vec{S_x}\vec{V_x} + m^2 \vec{S_y}\vec{V_y}\right) t
    + \vec{S_x}^2 + m^2 \vec{S_y}^2 - r^2
    = 0
\\]

See the discussion above with calculating this for a sphere.  The solution to the above equation yields ray intersections against a cylinder infinite along the z axis.  Once you have a point, you need only compare its z-coordinate to be \\(0 \ge z \ge h\\).


### Ray vs Torus
TBD

