# Shading Models

## Calculating Normal Vectors
We need a unit normal vector at each vertex.  The normal vector for a surface triangle can be done with:

> \\[ \vec{N} = \left( \vec{P_1} - \vec{P_0} \right) \times \left( \vec{P_2} - \vec{P_0} \right) \\]
>
> Where:
> * The vertices of the triangle \\(\vec{P_0}\\), \\(\vec{P_1}\\), \\(\vec{P_2}\\) are arranged in a counter-clockwise fashion when the normal faces towards the viewer.
> * Note that the above generates a normal that is NOT normalized.  You can still normalize it if you want, but more likely, you'll want to average this with other surface normals with the equation below.

A single vertex can be a point for multiple triangles. To get a single normal vector for the vertex,  we need a way to combine the normals for every adjacent surface.

\\[ \vec{N_\text{vertex}} = \frac{\sum_{i=1}^k \vec{N_i}}{\lVert \sum_{i=1}^k \vec{N_i} \rVert} \\]

Using unnormalized surfaces will influence the vertex normal towards larger surface areas, which usually looks better.

## Gouraud Shading

\\[ \kappa_{\text{primary}} = \varepsilon + \mathit{D} \mathit{A} + \mathit{D} \sum_{i=1}^n C_i \max \\{ \vec{N} \cdot \vec{L_i}, 0 \\} \\]

\\[ \kappa_{\text{secondary}} = \mathit{S} \sum_{i=1}^n C_i \max \\{ \vec{N} \cdot \vec{H_i} , 0 \\}^m \left( \vec{N} \cdot \vec{L_i} \gt 0 \right) \\]

\\(\kappa\\) is calculated for each vertex, then interpolates them for each pixel.

## Blinn-Phong Shading
The Blinn-Phong model takes the vertex normal \\(\vec{N}\\), the direction to a light source \\(\vec{L}\\), the direction to the viewer \\(\vec{V}\\), and interpolates these values across each triangle surface.  It calculates the halfway vector \\(\vec{H}\\) then applies its shading function to every pixel across the surface.

> \\[
    \kappa = \kappa_{\text{emission}} + \kappa_{\text{diffuse}} + \kappa_{\text{specular}} \\\\
    = \varepsilon \mathit{M} + \mathit{D} \mathit{T} \mathit{A} + \sum_{i=1}^n C_i
    \left[ \mathit{D} \mathit{T} \max \left\\{ \vec{N} \cdot \vec{L_i}, 0 \right\\} + \mathit{S} \mathit{G} \max \left\\{ \vec{N} \cdot \vec{H_i}, 0 \right\\}^m \left( \vec{N} \cdot \vec{L_i} \gt 0 \right)  \right]
\\]
>
> Where:
> * The diffuse and specular dot products are clamped to zero
> * The interpolated normal vectors do not retain the unit length they have at their vertices
> * \\(\varepsilon\\) is the emission color of the surface
> * \\(D\\) is the diffuse reflection color of the surface
> * \\(S\\) is the specular reflection color of the surface
> * \\(m\\) is the specular exponent color of the surface
> * \\(\vec{N}\\) is the normal of the surface
> * \\(M\\) is the emission sample from an emission map, if any, or 1.0
> * \\(G\\) is the specular sample from a gloss map, if any, or 1.0
> * \\(T\\) is the diffuse sample from a texture map, if any, or 1.0
> * \\(\vec{L_i}\\) is the vector pointing in the direction of light source \\(i\\)
> * \\(C_i\\) is the color of light source \\(i\\)
> * \\(\vec{H_i}\\) is the halfway vector for light source \\(i\\):
> \\[ \vec{H_i} = \frac{\vec{L_i} + \vec{V}}{\lVert \vec{L_i} + \vec{V} \rVert} \\]

To solve issue with the fact that normal vectors don't retain the unit-length at their vertices, we can explicitly normalize them in the fragment shader or use a normalization cube map.

## Bump Mapping
Each vector in a bump map is a representation of how the normal vector should be _perturbed_ relative to its original interpolated value. The vector \\( \langle 0, 0, 1 \rangle \\) represents an unperturbed normal vector.

Since the vector \\( \langle 0, 0, 1 \rangle \\) maps to the RGB value \\((\frac{1}{2}, \frac{1}{2}, 1) \\), bump maps (also known as normal maps) are blueish-purplish when viewed as a picture.

### Tangent Space
Bump maps exist in yet another coordinate space called _tangent space_.

We can construct a coordinate system at each vertex in which the vertex normal always points along the positive z axis.  In otherwords we need an _orthonormal basis_ in which the vertex's normal is the `k` unit vector.  We need to calculate `i` and `j`, which will be the tangent vector and bitangent vector, respectively.

Once we have this orthonormal basis, the direction from the vertex to each light source is calculated, then transformed into tangent space, which is then interpolated across the surface.

**The dot product between the tangent space direction to the light source and a sample from a bump map produces the diffuse reflection.**

The `tangent` vector should be aligned with the `s` axis in texture space.  The `bitangent` vector should be aligned with the `t` axis in texture space.

**Note**: I think that the texture coordinates might be oriented differently in different backends.  Need to double check this.

> \\[ \vec{Q} - \vec{P_0} = \left( s - s_0 \right) \vec{T} + \left( t - t_0 \right) \vec{B} \\]
>
> Where
> * \\(\vec{Q}\\) is an arbitrary point inside a triangle
> * \\(\vec{T}\\) is the tangent vector aligned to the texture map
> * \\(\vec{B}\\) is the bitangent vector aligned to the texture map
> * \\(\vec{P_0}\\) is the position of one of the vertices of the triangle
> * \\( \langle s_0, t_0 \rangle \\) are texture coordinates at the vertex \\(\vec{P_0}\\)

This is how to get the `tangent` and `bitangent` vectors:

\\[
    \begin{bmatrix} T_x & T_y & T_z \\\\ B_x & B_y & B_z \end{bmatrix} =
    \frac{1}{s_1 t_2 - s_2 t_1}
    \begin{bmatrix} t_2 & -t_1 \\\\ -s_2 & s_1 \end{bmatrix}
    \begin{bmatrix} (Q_1)_x & (Q_1)_y & (Q_1)_z \\\\ (Q_2)_x & (Q_2)_y & (Q_2)_z \end{bmatrix}
\\]

This generates the _unnormalized_ \\(\vec{T}\\) and \\(\vec{B}\\) for the **surface** of the triangle.  To get a single `tangent` and `bitangent` for each vertex, we have to average all the respective `tangent` and `bitangent` vectors at each adjacent surface.

Once we have \\(vec{N}\\), \\(vec{T}\\), and \\(vec{B}\\), it is important to understand that:
* They are still not normalized.
* They are not _necessarily_ orthogonal after the above calculations.
* We can use them to form the `tangent_to_model_space` matrix,  but we want the `model_to_tangent_space` matrix.

We can use Gram-Schmidt orthogonalization to make them truly orthogonal.  Normally this could really mess with the vector directions, but the tangent and bitangent are usually close enough that it should be OK.

\\[ \vec{T'} = \vec{T} - \left( \vec{N} \cdot \vec{T} \right) \vec{N} \\]
\\[ \vec{B'} = \vec{B} - \left( \vec{N} \cdot \vec{B} \right) \vec{N} - \left( \vec{T'} \cdot \vec{B} \right) \vec{T'} \\]

Now we can normalize these vectors.

After that, we can invert the matrix to form our `model_to_tangent_space` matrix. Since it's orthogonal, the inversion is just a transpose.

\\[ M_{\text{tangent} \rightarrow \text{model}} = \begin{bmatrix} T_x' & B_x' & N_x' \\\\ T_y' & B_y' & N_y' \\\\ T_z' & B_z' & N_z'\end{bmatrix} \\]

\\[ \left( M_{\text{tangent} \rightarrow \text{model}} \right)^{-1} = \left( M_{\text{tangent} \rightarrow \text{model}} \right)^{T} = M_{\text{model} \rightarrow \text{tangent}} = \begin{bmatrix} T_x' & T_y' & T_z' \\\\ B_x' & B_y' & B_z' \\\\ N_x' & N_y' & N_z'\end{bmatrix} \\]

