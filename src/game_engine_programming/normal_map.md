# Normal Maps

See:
* [https://gamedev.stackexchange.com/questions/63832/normals-vs-normal-maps](https://gamedev.stackexchange.com/questions/63832/normals-vs-normal-maps)
* [https://www.youtube.com/watch?v=PnazRFnPPcg](https://www.youtube.com/watch?v=PnazRFnPPcg)
* [http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/](http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/)
* [https://sotrh.github.io/learn-wgpu/intermediate/tutorial11-normals/#the-tangent-and-the-bitangent](https://sotrh.github.io/learn-wgpu/intermediate/tutorial11-normals/#the-tangent-and-the-bitangent)
* [https://learnopengl.com/Advanced-Lighting/Normal-Mapping](https://learnopengl.com/Advanced-Lighting/Normal-Mapping)

### Normal Vectors
The "normal" in geometry is a vector that is perpendicular to a given object.  They are primarily used in light calculations, for example to calculate the _diffuse reflection_ across a surface, which involves taking the dot product between the light direction and a surface normal.

Normals are also specified per vertex, even if they are calculated only for each face.

### Normal Maps
Normal mapping refers to a technique whereby a _texture map_, which is normally used for storing image data where for each texel is an RGB triplet of floats, is used to store normal vectors (also a triplet of floats).

Normal maps help fake the lighting of bumps and dents across a surface.

Normal maps, when opened in a UI tool, look blueish, because the Z-value is always calculated to be positive.  Since the Z value takes the "B" component, it will usually look more blue when viewed as an image.


### Tangent Space
Normal maps have always positive Zs because they are calculated and notated in `tangent space`, which is a coordinate system relative to the surface on which the normal was calculated.

This is done because normal maps are flat and they are used to wrap over 3D objects that may not be flat.  Since normals are defined in `tangent space`, we must construct a rotation matrix to re-orient each normal to the actual location on the object being wrapped.

To derive this rotation matrix, the vertex normals come in handy.  We first find the `tangent`, and `bitangent`, which taken together with the vertex `normal`, form a _basis_ for the `tangent space` coordinate system.  The _inverse_ of such a matrix is the `tangent space to world space` transformation matrix, which when applied to the normals in a normal map yield you correctly oriented normal vectors.

Since this `tangent space to world space` matrix is an `orthogonal matrix` (since the three vectors are basis vectors), the inverse of such a matrix is just the transpose, which makes it easy to calculate.
