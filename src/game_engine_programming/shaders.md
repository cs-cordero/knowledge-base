# Shaders

See:
* [https://thebookofshaders.com/06/](https://thebookofshaders.com/06/)
* [https://code.i-harness.com/en/q/1e5fff4](https://code.i-harness.com/en/q/1e5fff4)

## GLSL
GLSL is OpenGL's shader language.  `webGPU` is coming up with its own shader language, but as of this writing (Oct 13, 2020), the shader language it uses is SPIR-V, which can be cross-compiled from GLSL pretty well.

### Matrices: Row-Order vs Column-Order
OpenGL and, by extension, its shading language GLSL, use a column-order mapping for its matrices, e.g., `mat4`.

By contrast, my game engine _Grimoire_ utilizes row-order mapping for its matrix, `Matrix44`.

A matrix in column order:
1. has its translation components in the 4th column.
1. has its rotational components along the x-, y-, and z-axes in the first, second, and third columns respectively.

A matrix in row order:
1. has its translation components in the 4th row.
1. has its rotational components along the x-, y-, and z-axes in the first, second, and third rows respectively.

**Luckily**, when _Grimoire_ lays out its `Matrix44` sequentially in memory as a 1-dimensional array, when GLSL reads and instantiates the memory data into its `mat4` object, it correctly places the components in its necessary locations.

| 1D Array Index | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Matrix44 | m00 | m01 | m02 | m03 | m10 | m11 | m12 | m13 | m20 | m21 | m22 | m23 | m30 | m31 | m32 | m33 |
| mat4 | m00 | m10 | m20 | m30 | m01 | m11 | m21 | m31 | m02 | m12 | m22 | m32 | m03 | m13 | m23 | m33 |

From the table above, you can see that the translation components of a `Matrix44`, located at `m30`, `m31`, and `m32`, will be placed in the 1D array at indices 12, 13, and 14, respectively.

When GLSL reads the 1D array, it'll take the data at indices 12, 13, and 14, and place them correctly in the 4th column, at `m03`, `m13`, and `m23`, respectively.

### Matrices: Multiplication
In GLSL, multiplication between two `mat4`s work as you would expect.  The left-hand `mat4`'s rows are cross-multiplied against the right-hand `mat4`'s columns to generate another `mat4`.

Also, as you would expect, matrix multiplication is NOT commutative.  `Ma * Mb != Mb * Ma`.
