# OBJ and MTL files

See:
* [https://en.wikipedia.org/wiki/Wavefront_.obj_file](https://en.wikipedia.org/wiki/Wavefront_.obj_file)
* [OBJ Specification](http://www.martinreddy.net/gfx/3d/OBJ.spec)
* [MTL Specification](http://paulbourke.net/dataformats/mtl/)
* [http://www.fileformat.info/format/material/](http://www.fileformat.info/format/material/)


### OBJ
.OBJ files contain structural information for a 3D Model, i.e., the object mesh.

| Variable | Description |
|:---:|:--- |
|`v`| Geometric vertices with (x, y, z [, w = 1.0]) coordinates. |
|`vt`| Texture coordinates with (u [, v = 0, w =0]) where all values are in the inclusive range [0, 1]|
|`vn`| Vertex normals in (x, y, z) form.  *They may not be unit vectors* |
|`f`| Faces defined using lists of vertices identified by the index of how they were defined in the file.  **Indices start at 1** inside of OBJ files.

### MTL
.MTL files contain the graphical information to color in a 3D Model, i.e., colors, texture maps, bump maps, etc.

| Variable | Description |
|:---:|:--- |
|`Ka`| The ambient color of the material. RGB format. |
|`Kd`| The diffuse color of the material. RGB format. |
|`Ks`| The specular color of the material. RGB format. |
|`Ns`| The specular exponent of the material. f32 format in range [0, 1000]. |
|`d`| Dissolved (transparency).  f32 in the inclusive range [0, 1]. 1 means fully opaque. |
|`Tr`| The inverse of `d`: `1.0 - d`.  Transparency.
|`map_Ka`| The ambient texture map.
|`map_Kd`| The diffuse texture map (usually the same as ambient texture map).
|`map_Ks`| The specular texture map.
|`map_Bump`| The normal texture map.


When the `map_Ka`, `map_Kd`, and `map_Ks` texture maps are used, after getting the RGB color using a 2D sampler, the RGB values should be component-wise multiplied against the material RGB colors for `Ka`, `Kd`, and `Ks` respectively.

When the `map_Bump` exists and is used to calculate normal vectors, their values _replace_ the vertex normals (and the interpolated vertex normal values per fragment).

The vertex normals are still useful for calculating the `tangent space to world space` transformation matrix.  

See page in the Kb on normal maps for more information on this transformation matrix.

