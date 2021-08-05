# Vectors
Vectors are a foundational mathematical component to any 3D game engine.

See:
* [Quora: What is a pseudovector?](https://qr.ae/pNuwO2)
* [https://stackoverflow.com/https://en.wikipedia.org/wiki/Cross_product#Cross_product_and_handednessa/4820904/6602445](https://stackoverflow.com/a/4820904/6602445)
* [https://en.wikipedia.org/wiki/Cross_product#Cross_product_and_handedness](https://en.wikipedia.org/wiki/Cross_product#Cross_product_and_handedness)
* [https://www.reddit.com/r/askscience/comments/3rijds/why_does_the_righthandrule_for_vector/](https://www.reddit.com/r/askscience/comments/3rijds/why_does_the_righthandrule_for_vector/)

## Base Notation

Vectors take the following notation:

\\[ \vec{V} = \langle V_1, V_2, V_3, \ldots, V_n \rangle \\]

or, as a 4D Point.  3D game engines will be primarily concerned with its 3D and 4D representations, not just any arbitrary _n_.

\\[ \vec{P} = \langle P_x, P_y, P_z, P_w \rangle \\]

Each \\( V_i \\) are alled the _components_ of \\( \vec{V} \\).

## Vectors notated as a Matrix

Column vector:

\\[ \vec{V} = \begin{bmatrix}V_1 \\\\ V_2 \\\\ V_3 \\\\ \vdots \\\\ V_n\end{bmatrix} \\]

Row vector:

\\[ \vec{V^T} = \begin{bmatrix}V_1 & V_2 & V_3 & \cdots & V_n\end{bmatrix} \\]

The _T_ superscript in the row vector indicates that column and row vectors are transpositions of each other.

## Vector Space
All vectors belong to a _vector space_ denoted \\( ℝ^n \\), where n refers to the n-dimension of the vectors the vector space owns.

For example, the vector space consisting of all 3D vectors is \\( ℝ^3 \\).

A vector space can be defined by its `basis` vectors.  There will be _n_ such basis vectors for any given  \\( ℝ^n \\).  Basis vectors must be _linearly independent_, which means that there is no scalar _a_ that can be multiplied against one basis vector that will generate another basis vector. Basis vectors must also be orthogonal (and preferably orthonormal).

There are infinite choices for a set of _n_ vectors to serve as the basis for any \\( ℝ^n \\).  As soon as you find _n_ vectors, each orthogonal to each other, they can form yet another basis for the same vector space.

The basis vectors can, with scalar multiplication, generate any other vector in their entire vector space.

_Gram-Schmidt Orthogonalization_ can be used to transform a set of _n_ linearly independent vectors into a set of orthogonal vectors.

* All orthonormal sets of vectors are also orthogonal.
* All orthogonal sets of vectors are also linearly independent.
* All linearly independent sets of vectors are _not necessarily_ orthogonal.
* All orthogonal sets of vectors are _not necessarily_ orthonormal.

## Vector Operations

#### Scalar Multiplication
Scalars apply to each vector component.

\\[ \mathit{a}\vec{V} = \langle \mathit{a}V_1,\\;\mathit{a}V_2,\\;\ldots,\\;\mathit{a}V_n\rangle \\]


#### Addition and Subtraction
Vectors add and subtract component-wise.  Subtraction is a special case of addition that involves multiplying one vector by a scalar _-1_ before adding.

\\[ \vec{P} + \vec{Q} = \langle P_1+Q_2, \\; P_2+Q_2, \\; \ldots, \\; P_n+Q_n \rangle \\]

#### Magnitude
The _magnitude_ of a vector is also its length and can be found by summing the squares of its components and taking the square root.

The magnitude is also known as the _norm_ or the _length_ of a vector.

\\[ \lVert V \rVert = \sqrt{\sum_{i=1}^n{V_i^2}} \\]

#### Dot Product
The _dot product_ of two vectors is also known as the _scalar product_ or the _inner product_.

This measures the difference between the direction in which two vectors point.

\\[ \vec{P}\cdot\vec{Q} = \sum_{i=1}^n{P_i Q_i} \\]

\\[ \vec{P^T}\vec{Q} = \begin{bmatrix}P_1 & P_2 & \cdots & P_n \end{bmatrix} \begin{bmatrix}Q_1 \\\\ Q_2 \\\\ \vdots \\\\ Q_n \end{bmatrix} \\]

\\[ \vec{P}\cdot\vec{Q} = \lVert P \rVert \lVert Q \rVert cos\alpha \\]


##### Interpreting the Dot Product

\\( \vec{P}\cdot\vec{Q} = 0 \\)

* Two vectors \\( \vec{P} \\) and \\( \vec{Q} \\) are perpendicular if and only if \\( \vec{P}\cdot\vec{Q} = 0 \\).  This occurs only if the cosine of the angle between them is 0, and a cosine of an angle is 0 only if the angle is 90°.
* Perpendicular vectors are _orthogonal_ to one another. The zero vector is orthogonal to all vectors since for all \\( \vec{0}\cdot\vec{P} = 0 \\)


\\( \vec{P}\cdot\vec{Q} > 0 \\)

* Both vectors are pointing in the same direction.

\\( \vec{P}\cdot\vec{Q} < 0 \\)

* Both vectors are pointing in the opposite direction.

#### Projections
A vector can be projected onto another vector by decomposing some vector \\( \vec{P} \\) into two components that are parallel and perpendicular to another vector \\( \vec{Q} \\).

The projection will result in a vector in the parallel direction of \\( \vec{Q} \\), with a magnitude equal to the projection (it may not be unit-length anymore.)
\\[ proj_{\vec{Q}}\vec{P} = \frac{\vec{P}\cdot\vec{Q}}{{\lVert Q \rVert}^2}\vec{Q} \\] 

\\[ perp_{\vec{Q}}\vec{P} = \vec{P} - proj_{\vec{Q}}\vec{P} \\] 

The projection can also be viewed as a linear transformation and thereby a matrix-vector multiplication.

\\[ proj_{\vec{Q}}\vec{P} = \frac{1}{{\lVert Q \rVert}^2} \begin{bmatrix}Q_x^2 & Q_x Q_y & Q_x Q_z \\\\ Q_x Q_y & Q_y^2 & Q_y Q_z \\\\ Q_x Q_z & Q_y Q_z & Q_z^2 \end{bmatrix}\begin{bmatrix}P_x \\\\ P_y \\\\ P_z \end{bmatrix} \\]

#### Cross Product
The _cross product_ applies to **3D vectors only**.  It is known as the _vector product_ and it returns a new vector that is _perpendicular to both of the vectors being multiplied together_.

\\[ \vec{P} × \vec{Q} = \langle P_y Q_z - P_z Q_y, \\; P_z Q_x - P_x Q_z, \\; P_a Q_y - P_y Q_x \rangle \\]

The cross product also has trigonometric significance.

\\[ \lVert \vec{P} × \vec{Q} \rVert = \lVert \vec{P} \rVert \lVert \vec{Q} \rVert sin \alpha \\]

Although the cross product returns a vector that is perpendicular to the two vectors being multiplied, there are two possible directions.  Cross products follow a pattern called the _right hand rule_.  The following theorems demonstrate this.

\\[ \vec{i} × \vec{j} = \vec{k} \qquad \quad \vec{j} × \vec{i} = -\vec{k} \\]
\\[ \vec{j} × \vec{k} = \vec{i} \qquad \quad \vec{k} × \vec{j} = -\vec{i} \\]
\\[ \vec{k} × \vec{i} = \vec{j} \qquad \quad \vec{i} × \vec{k} = -\vec{j} \\]

#### Calculating the Area of an arbitrary triangle using cross product

\\[ A = \frac{1}{2}{(V_2 - V_1) × (V_3 - V_1)} \\]

## Special Vectors

#### Unit Vector
\\[ \text{Any} \\; \vec{v} \\; \text{such that} \\; \lVert v \rVert = 1 \\]

#### Zero Vector
\\[ \vec{0} = \langle 0, \\; 0, \\; \ldots, \\; 0 \rangle \\]

#### i, j, and k basis vectors
See the discussion above on Vector Space for information about basis vectors.

The basis vectors \\( \vec{i} \\), \\( \vec{j} \\), and \\( \vec{k} \\) are unit vectors that point along the x-, y-, and z-axis, respectively in  whatever coordinate space is contextually relevant.

\\[ \vec{i} = \langle 1, \\; 0, \\; 0 \rangle \\]
\\[ \vec{j} = \langle 0, \\; 1, \\; 0 \rangle \\]
\\[ \vec{k} = \langle 0, \\; 0, \\; 1 \rangle \\]
