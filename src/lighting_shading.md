# Lighting and Shading
In 3D game engines, _lighting_ is the process by which you determine the color and intensity of light reaching a particular surface.  _Shading_ determines the color and intensity of light reflected toward the viewer for each point on the surface.

## RGB Color
In graphics programming, a color is represented as a triplet of numbers, each number respectively representing the intensity of the colors Red, Green, and Blue.

Each component of the triplet takes a value in the inclusive range [0, 1], which is the level of intensity of that particular RGB color.

The terms "color" and "intensity" is sometimes used interchangeably when referring to what emitted by a light source.  If we say "ambient intensity", we actually mean the triplet color of the ambient light source.

Below, any capital letter in italics, e.g. \\(\mathit{D}\\), that refers to a color.

Additional resources:
* [https://en.wikipedia.org/wiki/RGB_color_model](https://en.wikipedia.org/wiki/RGB_color_model)
* [https://en.wikipedia.org/wiki/RGBA_color_model](https://en.wikipedia.org/wiki/RGBA_color_model)
* [https://en.wikipedia.org/wiki/Comparison_of_color_models_in_computer_graphics](https://en.wikipedia.org/wiki/Comparison_of_color_models_in_computer_graphics)

\\[ \mathit{C} = (\mathit{C}_r, \mathit{C}_g, \mathit{C}_b) \\]

## Color Operations

### Scalar multiplication
Multiplying by a scalar occurs component-wise.

\\[ s \mathit{C} = (s \mathit{C}_r, s \mathit{C}_g, s \mathit{C}_b) \\]

### Addition
Adding two colors occurs component-wise.

\\[ \mathit{C} + \mathit{D} = (\mathit{C}_r + \mathit{D}_r, \mathit{C}_g + \mathit{D}_g, \mathit{C}_b + \mathit{D}_b) \\]

### Multiplication
Multiplying two colors occurs component-wise.

\\[ \mathit{C} \mathit{D} = (\mathit{C}_r \mathit{D}_r, \mathit{C}_g \mathit{D}_g, \mathit{C}_b \mathit{D}_b) \\]


## Types of Light

### Ambient Light
This is the low-intensity light which comes from many reflections of light on nearby surfaces.

This appears to come in every direction in equal intensity and illuminates every part of an object uniformly.  Within a scene, the ambient strength is most often constant, but it is possible to use a 3D texture map to sample ambient light within every point in the world.

### Directional Light
A light source that shoots light in a single direction from infinitely far away.

### Point Light
A light source that radiates light equally in every direction from a single point in space.  Light intensity drops off according to the inverse square law.

> \\[ \mathit{C} = \frac{1}{k_c + k_l q + k_q d^2} \mathit{C}_0 \\]
> 
> Let:
> * \\( \vec{P} \\) is the location in space of the point light
> * \\( \vec{Q} \\) is an arbitrary point in space.
> 
> Where:
> * \\( C_0 \\) is the color of the light
> * \\( d \\) is distance, i.e. \\( \lVert \vec{P} - \vec{Q} \rVert \\)
> * \\(k_c\\), \\(k_l\\), \\(k_q\\) are the constant, linear, and quadratic attenuation constants, respectively.

### Spot Light
Similar to a point light but has a preferred direction of radiation (like a flashlight).  Intensity of a spot light is attenuated over distance the same way for a point light.  It is also attenuated for the "spot light effect".

> \\[ \mathit{C} = \frac{max\\{-\vec{R} \cdot \vec{L}, 0 \\}^p}{k_c + k_l q + k_q d^2} \mathit{C}_0 \\]
>
> Let:
> * \\( \vec{P} \\) is the location of the spot light.
> * \\( \vec{Q} \\) is an arbitrary point in space.
> * \\( \vec{R} \\) is the direction of the spot light.
> * \\( \vec{L} \\) is the unit-length direction pointing from \\( \vec{Q} \\) toward the light source.
>
> Where:
> * \\( \vec{L} = \frac{\vec{P} - \vec{Q}}{\lVert \vec{P} - \vec{Q} \rVert} \\)
> * \\( C_0 \\) is the color of the light
> * \\( d \\) is the distance between the \\( \vec{P} \\) and \\( \vec{Q} \\).
> * \\(k_c\\), \\(k_l\\), \\(k_q\\) are the constant, linear, and quadratic attenuation constants, respectively.

## Diffuse Reflection

### Lambertian Reflection
When light hits a diffuse surface, the light is scattered in random directions.  The surface's diffuse reflection color is therefore reflected uniformly in every direction.  Since light is reflected uniformly in _every_ direction, the appearance of the reflection does not depend on the position of the observer.

> \\[ \kappa_{\text{diffuse}} = \mathit{D} \mathit{A} + \mathit{D} \sum_{i=1}^n C_i \max \left\\{ \vec{N} \cdot \vec{L_i}, 0 \right\\} \\]
>
> Where:
> * D is the surface's diffuse reflection color
> * n is the different light sources
> * A is ambient light intensity
> * \\(\vec{L_i}\\) is the unit vector pointing from an arbitrary point on the surface toward the light source \\(i\\)
> * \\(\vec{N}\\) is the normal unit vector of the surface
> * \\(C_i\\) is the intensity of light source \\(i\\)

## Specular Reflection
When light hits a surface, light tends to be reflected more strongly in the direction reflected across the surface's normal vector.  In human terms, this is the light that reflects "just right" across a surface super brightly.  The intensity of the light drops off as the angle between the viewer and this reflection increases.

Specular reflection therefore depends on the position of the viewer.

The following calculates the specular contribution from a single light source.  **Don't use this!** See the alternative calculation below.

> \\[ \mathit{S} \mathit{C} \max \left\\{ \vec{R} \cdot \vec{V}, 0 \right\\}^m \left(\vec{N} \cdot \vec{L} \gt 0\right) \\]
>
> Where:
> * \\(\mathit{S}\\) is the surface's specular reflection color
> * \\(\mathit{C}\\) is the intensity of the light source
> * \\(m\\) is the _specular exponent_
> * The expression \\(\left(\vec{N} \cdot \vec{L} > 0\right)\\) is 1 if true else 0
> * \\(\vec{N}\\) is the normal vector of the surface
> * \\(\vec{L}\\) is the unit vector pointing in the direction toward the light source
> * \\(\vec{R}\\) is the unit vector of \\(\vec{L}\\) having been reflected across the normal
> * \\(\vec{V}\\) is the unit vector pointing in the direction toward the viewer/observer

### Alternative (and better) calculation
A more efficient calculation of the specular reflection uses a _halfway vector_ which is the unit vector exactly halfway between the light source unit vector and the viewer unit vector.

> \\[ \kappa_{\text{specular}} = \mathit{S} \sum_{i=1}^n \mathit{C}_i \max \left\\{ \vec{N} \cdot \vec{H_i}, 0 \right\\}^m \left( \vec{N} \cdot \vec{L_i} \gt 0 \right) \\]
>
> Where:
> * \\( \vec{H_i} \\) is the halfway vector for light source \\(i\\):
> \\[ \vec{H_i} = \frac{\vec{L_i} + \vec{V}}{\lVert \vec{L_i} + \vec{V} \rVert} \\]
> * \\(\vec{L_i}\\) is the unit vector pointing in the direction toward the light source \\(i\\)
> * \\(\vec{V}\\) is the unit vector pointing in the direction toward the viewer/observer
> * \\(\vec{N}\\) is the normal vector of the surface
> * \\(\mathit{S}\\) is the surface's specular reflection color
> * \\(\mathit{C}_i\\) is the intensity of the light source \\(i\\)
> * \\(m\\) is the _specular exponent_
> * \\(\vec{N}\\) is the normal vector of the surface

## Emission
Some objects emit light in addition to reflecting it.

> \\[ \kappa_{\text{emission}} = \varepsilon \mathit{M} \\]
>
> Where:
> * \\(\varepsilon\\) is the emission color
> * \\(\mathit{M}\\) is a sample from an emission map.  This is optional, but is useful if you want it to be modulated over the object's surface.

## Texture Mapping

### Diffuse Lighting with Texture Map
Colors from a diffuse texture map can modulate the diffuse reflection color.

> \\[ \kappa_{\text{diffuse}} = \mathit{D} \mathit{T} \mathit{A} + \mathit{D} \mathit{T} \sum_{i=1}^n C_i \max \left\\{ \vec{N} \cdot \vec{L_i}, 0 \right\\} \\]
>
> Where:
> * T is the color sampled from the texture map
> * D is the surface's diffuse reflection color
> * n is the different light sources
> * A is ambient light intensity
> * \\(\vec{L_i}\\) is the unit vector pointing from an arbitrary point on the surface toward the light source \\(i\\)
> * \\(\vec{N}\\) is the normal unit vector of the surface
> * \\(C_i\\) is the intensity of light source \\(i\\)

### Specular Lighting with Texture Map
Colors from a gloss map can module the specular reflection color.

> \\[ \kappa_{\text{specular}} = \mathit{S} \mathit{G} \sum_{i=1}^n \mathit{C}_i \max \left\\{ \vec{N} \cdot \vec{H_i}, 0 \right\\}^m \left( \vec{N} \cdot \vec{L_i} \gt 0 \right) \\]
>
> Where:
> * G is the color sampled from the gloss map.
> * \\( \vec{H_i} \\) is the halfway vector for light source \\(i\\):
> \\[ \vec{H_i} = \frac{\vec{L_i} + \vec{V}}{\lVert \vec{L_i} + \vec{V} \rVert} \\]
> * \\(\vec{L_i}\\) is the unit vector pointing in the direction toward the light source \\(i\\)
> * \\(\vec{V}\\) is the unit vector pointing in the direction toward the viewer/observer
> * \\(\vec{N}\\) is the normal vector of the surface
> * \\(\mathit{S}\\) is the surface's specular reflection color
> * \\(\mathit{C}_i\\) is the intensity of the light source \\(i\\)
> * \\(m\\) is the _specular exponent_
> * \\(\vec{N}\\) is the normal vector of the surface

### Projective Texture Maps
1D, 2D and 3D texture maps use the coordinates `s`, `t`, and `p`.  There is also a fourth coordinate `q` for _projective texture maps_.

Kind of like homogenous coordinates, `q` is assumed to be 1 when not specified.  `s`, `t`, and `p` are divided by `q`.

These are useful for projecting an image out onto the environment (like a projector screen).

\\[ \langle s, t, p, q \rangle \\]

For two texture coordinates, we can interpolate along the line between them using this.  Do this for `s`, `t`, and `p`.

> \\[ s = \frac{s_3}{q_3} = \frac{ \left( 1 - u \right) \frac{s_1}{z_1} + u \frac{s_2}{z_2} }{ \left( 1 - u \right) \frac{q_1}{z_1} + u \frac{q_2}{z_2} } \\]
>
> Where:
> * \\(z\\) are depth values
> * \\(u\\) is the interpolation parameter within the inclusive range [0, 1]

### Cube Texture Maps
Often used to approximate an environment's reflection on the surface of an object.
