# Ray Tracing

Ray tracing is any algorithm that follows rays (in the form of light, sight, or anything else that can be projected outward), to determine with which objects they interact in the world.

Useful for:
* light map generation
* visibility determination
* collision detection
* line of sight testing

Most often you'll define the ray as a line and then determine at the points of intersection with some other object.

## Root Finding

A line is defined as:

> \\[ \vec{P}(t) = \vec{S} + t \vec{V} \\]
> 
> Where:
> * \\(\vec{P}\\) is the point along the line at "time" \\(t\\).
> * \\(\vec{S}\\) is the starting point of the ray.
> * \\(\vec{V}\\) is the direction that the ray is pointing.
> * \\(t\\) is some measure of "time".  As it increases, the line moves in the directin of \\(\vec{V}\\).

To find where this line intersects a surface requires finding the "**roots of a degree \\(n\\) polynomial** in \\(t\\)."  This `degree` depends on the surface itself.
* For planar surfaces, the `degree` is 1.
* For quadric surfaces, e.g., sphere or cylinder, the `degree` is 2.
* For complex surfaces, e.g., splines and 'tori', the `degree` is 3 or 4.

## Quadratic Polynomial

\\[ a t^2 + b t + c = 0 \\]

\\[ t = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} \\]

The quantity \\( D = b^2 - 4ac \\) is called the **discriminant** and determines how many real roots (aka solutions) there are to the quadratic equation.
* When \\(D \gt 0\\), there are two real roots.
* When \\(D = 0\\), there is one real root.
* When \\(D \lt 0\\), there are no real roots.

Solving the discriminant is enough for us to know whether the ray will intersect an object without actually calculating the intersection points.

## Cubic Polynomials

\\[t^3 + at^2 + bt + c = 0\\]

> \\[D = -4p^3 - 27q^2\\]
>
> Where:
> \\[p = -\frac{1}{3} a^2 + b\\]
> \\[q=\frac{2}{27} a^3 - \frac{1}{3} ab + c\\]

> The three complex roots are:
> \\[x_1 = r + s\\]
> \\[x_2 = \rho r + \rho^2 s\\]
> \\[x_3 = \rho^2 r + \rho s\\]
>
> Where:
> \\[r = \sqrt[3]{-\frac{1}{2} q + \sqrt{-\frac{1}{108} D}}\\]
> \\[s = \sqrt[3]{-\frac{1}{2} q - \sqrt{-\frac{1}{108} D}}\\]
> \\[\rho = -\frac{1}{2} + i \frac{\sqrt{3}}{2} \\]
> \\[\rho^2 = -\frac{1}{2} - i \frac{\sqrt{3}}{2} \\]

## Newton's  Method
A technique that can find the roots of an arbitrary continuous function by iterating a formula that depends on the function and its derivative.

Given a continuous function \\(f\\), any point at \\(x_i\\) along the function is given as \\(\left( x_i, f(x_i) \right)\\).

The slope of the line _tangent_ to that point along the curve is given by the derivative \\(f'(x_i)\\). This tangent line has the following equation:

\\[y - f(x_i) = f'(x_i)(x - x_i)\\]

Setting \\(y = 0\\), and relabeling \\(x\\) as \\(x_{i+1}\\), we can derive the following:
\\[x_{i+1} = x_i - \frac{f(x_i)}{f'(x_i)}\\]

This equation generates a sequence \\(x_0, x_1, x_2, ...\\) which, under the right conditions, approaches the root of the original function \\(f\\).


This technique is not guaranteed to always work.  If the tangent slope is 0, the line is horizontal and will never intersect the x-axis where \\(y = 0\\).

Picking the first \\(x\\) value, \\(x_0\\) should be carefully done. This can be done by first intersecting the ray with the surface of a relatively simple bounding volume.
