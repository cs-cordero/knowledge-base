# Physical Reflection Models
Blinn-Phong is a cheap calculation of lighting but it is not an accurate model of how light physically distributes itself.  We need to use electromagnetic theory to get even more realistic.

A **bidirectional reflectance distribution function (BRDF)** is a function which takes:
* as input: A direction \\(\vec{L}\\) to a light source
* as input: A reflection direction \\(\vec{R}\\)
* as output: the amount of incident light from the direction \\(\vec{L}\\) reflected in the \\(\vec{R}\\) direction


##### Flux density
The power emitted by a light source or received by a surface per unit area, measured in watts per square meter, \\(\frac{W}{m^2}\\).

_Radiosity_ is the flux density emitted by a surface.

_Irradiance_ of a light is the flux density incident on a surface.

The power emitted by the light source differs from teh power received by a surface due to the _Lambertian effect_, and it is modeled like so:

> \\[ \phi_I = \frac{P}{A} \\ = \phi_E \left( \vec{N} \cdot \vec{L} \right) \\]
> 
> \\[ \phi_E = \phi_I \frac{1}{\left( \vec{N} \cdot \vec{L} \right)} = \frac{P}{A \left( \vec{N} \cdot \vec{L} \right)} \\]
>
> Where:
> * \\(\phi_E\\) is the light emitted by a light source
> * \\(\phi_I\\) is the light incident on a surface
> * \\(P\\) is the watts of power emitted by the light source.
> * \\(A\\) is area of the surface receiving the light
> * \\(\vec{N}\\) is the surface normal
> * \\(\vec{L}\\) is the unit vector pointing toward the light source.
