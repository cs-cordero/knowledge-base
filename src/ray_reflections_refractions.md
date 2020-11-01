# Reflections and Refractions
When a beam of light hits a surface a few things may happen to that beam:
1. Some of its energy is **absorbed** by the surface.
1. Some of its energy is **reflected** away from the surface.
1. Some of its energy is **transmitted** through the surface.

### Reflection
The angle of incidence is equal to the angle of reflection.

Given a vector \\(\vec{L}\\) pointing **in the direction of** the incoming light originating from the strike point, the angle between this vector and the normal vector of this surface is the angle of incidence.

This angle is equal to the angle of reflection, which generates the reflected vector \\(\vec{R}\\).

First, we calculate the component of \\(\vec{L}\\) that is perpendicular to the normal.  **Assume that both \\(\vec{L}\\) and \\(\vec{N}\\) are unit-length.**

\\[ \text{perp}_N \vec{L} = \vec{L} - (\vec{N} \cdot \vec{L}) \vec{N} \\]

Second, we can derive \\(\vec{R}\\) using a bit of logic.  The reflected vector should be equal to the original vector, minus 2x the perpendicular direction.

\\[
    \begin{align}
    \vec{R} & = \vec{L} - 2 \text{perp}_N \vec{L} \\\\
    & = \vec{L} - 2 \left(\vec{L} - (\vec{N} \cdot \vec{L}) \vec{N}\right) \\\\
    & = 2 (\vec{N} \cdot \vec{L}) \vec{N} - \vec{L}
    \end{align}
\\]


### Refraction
Transparent surfaces possess a property called the **index of refraction**.

[Snell's law](https://en.wikipedia.org/wiki/Snell%27s_law) tells us that the angle of incidence, \\(\theta_L\\) is related to the angle of transmission, \\(\theta_T\\) in this way:

> \\[ \eta_L \sin{\theta_L} = \eta_T \sin{\theta_T} \\]
>
> Where
> * \\( \eta_L \\) is the index of refraction of the material the light source is _leaving_.
> * \\( \eta_T \\) is the index of refraction of the material the light source is _entering_.

The index of refraction of air (usually \\(\eta_L\\)) is typically 1.00.

##### TODO: Show how the below equation is derived.

> \\[ \vec{T} =
> \left(
>   \frac{\eta_L}{\eta_T} \vec{N} \cdot \vec{L} -
>   \sqrt{
>       1 - \frac{\eta_L^2}{\eta_T^2}
>       \left[1 - (\vec{N} \cdot \vec{L})^2\right]
>   }
> \right)
> \vec{N} - \frac{\eta_L}{\eta_T} \vec{L}
> \\]
>
> Where
> * \\(\vec{N}\\) is the unit-length normal vector.
> * \\(\vec{L}\\) is the unit-length vector in the direction of the light.
> * \\(\vec{T}\\) is the direction in which light is transmitted when leaving a medium with index of refraction \\(\eta_L\\) and enternig a medium with index of refraction \\(\eta_T\\).
