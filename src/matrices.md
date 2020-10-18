# Matrices
Matrices are a foundational mathematical component to any 3D game engine.

## Base Notation

Matrices take the following notation:

\\[M = \begin{bmatrix} M_{11} & M_{12} & M_{13} & M_{14} \\\\ M_{21} & M_{22} & M_{23} & M_{24} \\\\ M_{31} & M_{32} & M_{33} & M_{34} \\\\ M_{41} & M_{42} & M_{43} & M_{44} \end{bmatrix}\\]

When the row number and column number equal, e.g., \\( M_{11} \\), \\( M_{22} \\), etc., those components make up the _main diagonal_ entries of the matrix.

\\[M^T = \begin{bmatrix} M_{11} & M_{21} & M_{31} & M_{41} \\\\ M_{12} & M_{22} & M_{32} & M_{42} \\\\ M_{13} & M_{23} & M_{33} & M_{43} \\\\ M_{14} & M_{24} & M_{34} & M_{44} \end{bmatrix}\\]

The rows of a matrix are often denoted with _n_, and the columns are denoted with _m_.  Matrix sizes take the notation _n_ x _m_.

## Linear Systems as Matrix
Matrices can represent a system of linear equations.  Suppose you have this system:
\\[ 3x + 2y - 3z = -13 \\]
\\[ 4x - 3y + 6z = 7 \\]
\\[ x - z = -5 \\]

This can be represented in matrix form as:

\\[
    \begin{bmatrix}
        3 & 2 & -3 \\\\
        4 & -3 & 6 \\\\
        1 & 0 & -1
    \end{bmatrix}
    \begin{bmatrix} x \\\\ y \\\\ z \end{bmatrix}
    =
    \begin{bmatrix} -13 \\\\ 7 \\\\ -5 \end{bmatrix}
\\]

* The 3x3 matrix is called the _coefficient matrix_.
* The column vector on the right-hand side is called the _constant vector_.
    * When the _constant vector_ is nonzero, the linear system is _nonhomogenous_.
    * When the _constant vector_ is zero, the linear system is _homogenous_.
    
The _coefficient matrix_ and the _constant vector_ can be joined together to form the _augmented matrix_ below:

\\[\left\[
    \begin{array}{ccc|c}
        3 & 2 & -3 & -13 \\\\
        4 & -3 & 6 & 7 \\\\
        1 & 0 & -1 & -5
    \end{array}
\right\]\\]

##### Reduced Form
A matrix is in reduced form if all of the following conditions hold true:
* \\( \mathit{m} \le \mathit{n} \\)
* For every nonzero row, the leading entry is equal to 1.
* Every leading entry is to the left of the leading entries of all lower rows.
* All zero rows reside at the bottom of the matrix.

You may perform _elementary row operations_ on an augmented matrix in an effort to find its reduced form.  The following are such elementary row operations:
* Exchange two rows.
* A Multiple a row by a non-zero scalar.
* Add a multiple of one row to another row.

## Matrix Determinants
The determinant of a square matrix is a scalar quantity computed from the matrix's elements and is denoted \\( \text{det}\\, A \\; \text{or} \\; \lvert A \rvert \\).

Geometrically, it can be viewed as the _volume scaling factor_ of the linear
transformation described by the matrix.

For a 2x2 matrix:

\\[ \text{det}\\, A = \begin{vmatrix} a & b \\\\ c & d \end{vmatrix} = ad - bc \\]

For a 3x3 matrix:

\\[ \text{det}\\, A = \begin{vmatrix} a & b & c \\\\ d & e & f \\\\ g & h & i \end{vmatrix} =
    a \begin{vmatrix}
        e & f \\\\
        h & i
    \end{vmatrix} - b \begin{vmatrix}
        d & f \\\\
        g & i
   \end{vmatrix} + c \begin{vmatrix}
        d & e \\\\
        g &h
   \end{vmatrix} = aei + bfg + cdh - ceg - bdi - afh
\\]


For a 4x4 matrix:

\\[ \text{det}\\, A =
    \begin{vmatrix}
        a & b & c & d\\\\
        e & f & g & h \\\\
        i & j & k & l \\\\
        m & n & o & p
    \end{vmatrix} =
    a \begin{vmatrix}
        f & g & h \\\\
        j & k & l \\\\
        n & o & p
    \end{vmatrix}
    - b \begin{vmatrix}
        e & g & h \\\\
        i & k & l \\\\
        m & o & p
    \end{vmatrix}
    + c \begin{vmatrix}
        e & f & h \\\\
        i & j & l \\\\
        m & n & p
    \end{vmatrix}
    - d \begin{vmatrix}
        e & f & g \\\\
        i & j & k \\\\
        m & n & o
    \end{vmatrix} \\\\
    = afkp + agln + ahjo - ahkn - agjp - aflo - bekp - celn \\\\
    - dejo + dekp + cejp + belo + bgip + chin + dfio - dgin \\\\
    - cfip - bhio - bglm - chjm - dfkm + dgjm + cflm + bhkm
\\]

Note that the notation for the brackets are vertical bars instead of the regular brackets in matrices.  This indicates that we are calculating for the determinant.

Calculating the determinant is recursive for any _n_ x _n_.  The 2x2 matrix is the "base" case.  Notice how in the 3x3 calculation, it composes into a series of scalars multiplied by 2x2 matrices, which further decompose into the final calculation.

Similarly, a 4x4 matrix decomposes into scalars multiplied by 3x3 matrices.  These 3x3 matrices will need to further decompose into scalars multiplied by 2x2 matrices, and so on.

##### Determinant theorems
* The determinant of a matrix having two identical rows is zero.
* For any two _n_ x _n_ matrices F and G, \\( \text{det}\\, FG = \text{det}\\, F \\, \text{det}\\, G \\)
* If the determinant is 0, the matrix cannot be inverted.

## Eigenvalues and Eigenvectors
For every invertible square matrix, there exist a nonzero number of vectors that when multiplied by the matrix are only changed in magnitude and not direction.

\\[ MV_i = \lambda_i V_i \\]

The scalars \\( \lambda_i \\) are the _eigenvalues_ of matrix M.

The vectors \\( V_i \\) are the _eigenvectors_ of matrix M.

A _symmetric_ matrix has entries that are symmetric about the main diagonal, aka where \\( M_{ij} = M_{ji} \text{ for all } i \text{ and } j \\).

The eigenvalues of a symmetric matrix having real entires are real numbers.  Otherwise, they are complex numbers.

**Any two eigenvectors associated with distinct eigenvalues of a symmetric matrix M are orthogonal.**

We can calculate the eigenvalues \\( \lambda_i \\) by solving the equation

\\[ \text{det}(M - \lambda I) = 0 \\]

> **Example**
> \\[ \text{Let }M = \begin{bmatrix} 1 & 1 \\\\ 3 & -1 \end{bmatrix} \\]
>
> \\[
>     M - \lambda I =
>         \begin{bmatrix} 1 - \lambda & 1 \\\\ 3 & -1 - \lambda \end{bmatrix} = 0 \\\\
>         = (1 - \lambda)(-1 - \lambda) - 3 = 0 \\\\
>         = \lambda^2 - 4 = 0 \\\\
> \\]
>
> \\[ \lambda = \pm 2 \\]
> 
> The eigenvalues of M are 2 and -2.

Once we have calculated the eigenvalues, we can get the eigenvectors by solving the following homogenous system 

\\[ (M - \lambda_i) V_i = 0 \\]

> **Example**
>
> For \\( \lambda_1 = 2 \\), we have:
> \\[ \begin{bmatrix} -1 & 1 \\\\ 3 & -3 \end{bmatrix} \vec{V_1} = \begin{bmatrix} 0 \\\\ 0 \end{bmatrix} \\]
>
> For \\( \lambda_2 = -2 \\), we have:
> \\[ \begin{bmatrix} 3 & 1 \\\\ 3 & 1 \end{bmatrix} \vec{V_2} = \begin{bmatrix} 0 \\\\ 0 \end{bmatrix} \\]
> 
> Both are solved to:
> \\[ \vec{V_1} = a \begin{bmatrix} 1 \\\\ 1 \end{bmatrix} \\]
> \\[ \vec{V_2} = b \begin{bmatrix} 1 \\\\ -3 \end{bmatrix} \\]
> where \\( a \\) and \\( b \\) are arbitrary nonzero constants.

## Diagonalization
A _diagonal matrix_ is one that has nonzero entires only along the main diagonal.

If we can find a matrix A such that \\( A^{-1} M A \\) is a diagonal matrix, we say that A _diagonalizes_ M.

In general, if we can find _n_ eigenvectors for an _n_ x _n_ matrix, the matrix can be diagonalized.

> **Determining the diagonalization matrix**
>
> If the _n_ x _n_ matrix M has eigenvalues \\(\lambda_1, \\, lambda_2, \\, \ldots, \\, \lambda_n \\) and corresponding eigenvectors \\( \vec{V_1}, \\, \vec{V_2}, \\, \ldots, \\, \vec{V_n} \\) then the matrix A is:
>
> \\[ A = \left\[ \vec{V_1} \quad \vec{V_2} \quad \cdots \quad \vec{V_n} \right\] \\]
> Note: each vector make up the _columns_ of the matrix.  A will diagonalize the matrix M and set its diagonal values equal to the eigenvalues.
>
> \\[ A^{-1} M A = \begin{bmatrix}
    \lambda_1 & 0 & \cdots & 0 \\\\
    0 & \lambda_2 & \cdots & 0 \\\\
    \vdots & \vdots & \ddots & \vdots \\\\
    0 & 0 & \cdots & \lambda_n
\end{bmatrix}
\\]

## Matrix Operations

#### Scalar Multiplication
Scalars apply to each matrix component.

\\[ \mathit{a}M = M \mathit{a} =
    \begin{bmatrix}
        \mathit{a}M_{11} & \mathit{a}M_{12} & \cdots & \mathit{a}M_{1m} \\\\
        \mathit{a}M_{21} & \mathit{a}M_{22} & \cdots & \mathit{a}M_{2m} \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        \mathit{a}M_{n1} & \mathit{a}M_{n2} & \cdots & \mathit{a}M_{nm}
    \end{bmatrix}
\\]


#### Addition
Matrices add component-wise.

\\[ F + G =
    \begin{bmatrix}
        F_{11}+G_{11} & F_{12}+G_{12} & \cdots & F_{1m}+G_{1m} \\\\
        F_{21}+G_{21} & F_{22}+G_{22} & \cdots & F_{2m}+G_{2m} \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        F_{n1}+G_{n1} & F_{n2}+G_{n2} & \cdots & F_{nm}+G_{nm}
    \end{bmatrix}
\\]

#### Matrix Multiplication
Two matrices may be multiplified if and only if the left-hand matrix's column count equals the right-hand matrix's row count, such that _n_ x _m_ = _m_ x _p_.

The result of the multiplication is a _n_ x _p_ matrix where each entry is calculated with dot products.

\\[ \left\( FG \right\)_{ij} = \sum\_{k=1}^m{F\_{ik} G\_{kj}} \\]

\\[ FG =
    \begin{bmatrix}
        \sum\_{k=1}^m{F\_{1k} G\_{k1}} & \sum\_{k=1}^m{F\_{1k} G\_{k2}} & \cdots & \sum\_{k=1}^m{F\_{1k} G\_{kp}} \\\\
        \sum\_{k=1}^m{F\_{2k} G\_{k1}} & \sum\_{k=1}^m{F\_{2k} G\_{k2}} & \cdots & \sum\_{k=1}^m{F\_{2k} G\_{kp}} \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        \sum\_{k=1}^m{F\_{nk} G\_{k1}} & \sum\_{k=1}^m{F\_{nk} G\_{k2}} & \cdots & \sum\_{k=1}^m{F\_{nk} G\_{kp}} \\\\
    \end{bmatrix}
\\]

#### Matrix Inversion
Not all matrices can be inverted.
* The matrix must be a square matrix of size _n_ x _n_.
* The matrix must not have any rows or columns entirely of zeros.
* If two matrices, F and G, are invertible, their matrix product FG is also invertible.

Multiplying a matrix by its inverse returns the identity matrix.

\\[ M M^{-1} = M^{-1} M = I \\]

The inverse of the product of two matrices is equal to the reverse product of their inversed components.
\\[ \left\( FG \right\)^{-1} = G^{-1} F^{-1} \\]

Calculating the inverse of an arbitrary matrix can be computationally expensive.  One algorithm useful for calculating this is the _Gauss-Jordan Elimination_ algorithm.

##### The _determinant_ of the matrix can be used to find the inverse of a matrix.
The determinant must not be 0. If it is 0, the matrix is not invertible.

For a 2x2 matrix:

\\[ M^{-1} = \frac{1}{\text{det}\\, M} \begin{bmatrix} M_{22} & -M_{12} \\\\ -M_{21} & M_{11} \end{bmatrix} \\]

For a 3x3 matrix:

\\[ M^{-1} = \frac{1}{\text{det}\\, M}
    \begin{bmatrix}
        M_{22} M_{33} - M_{23} M_{32} & M_{13} M_{32} - M_{12} M_{33} & M_{12} M_{23} - M_{13} M_{22} \\\\
        M_{23} M_{31} - M_{21} M_{33} & M_{11} M_{33} - M_{13} M_{31} & M_{13} M_{21} - M_{11} M_{23} \\\\
        M_{21} M_{32} - M_{22} M_{31} & M_{12} M_{31} - M_{11} M_{32} & M_{11} M_{22} - M_{12} M_{21}
    \end{bmatrix}
\\]

## Special Matrices

#### Identity Matrix
Any matrix M multiplied against or by the identity matrix _I_ returns M.

\\[
    \begin{bmatrix}
        1 & 0 & \cdots & 0 \\\\
        0 & 1 & \cdots & 0 \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        0 & 0 & \cdots & 1
    \end{bmatrix}
\\]

#### Symmetric Matrix
Any matrix with entries that are symmetrical about the main diagonal.

\\[
    \begin{bmatrix}
        x & a & \cdots & b \\\\
        a & y & \cdots & c \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        b & c & \cdots & z
    \end{bmatrix}, \\\\
    \text{where }x, y, \text{ and } z \text{ are arbitrary values.}
\\]

#### Diagonal Matrix
Any matrix with its nonzero values only along the main diagonal.

\\[
    \begin{bmatrix}
        \lambda_1 & 0 & \cdots & 0 \\\\
        0 & \lambda_2 & \cdots & 0 \\\\
        \vdots & \vdots & \ddots & \vdots \\\\
        0 & 0 & \cdots & \lambda_n
    \end{bmatrix}
\\]

#### Orthogonal Matrix
Any matrix whose inverse is equal to its transpose.  Most 3x3 matrices in 3D graphics are orthogonal.

Might be obvious, but an orthogonal matrix must be invertible.

\\[ M^{-1} = M^T \\]

Furthermore:  if the vectors \\( V_1, V_2, \ldots, V_n \\) form an orthonormal set, then the _n_ x _n_ matrix \\( M = [V_1, V_2, \ldots, V_n] \\), where each vector is a _column_, is orthogonal.
