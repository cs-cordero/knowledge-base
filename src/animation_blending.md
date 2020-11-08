# Blending
Animation blending is any technique that allows more than one animation clip to contribute to the final pose.

Two or more input poses produce a single output pose for the skeleton.

Blending has two uses:
* Combining two smaller animations into one animation, such as injured animation + walking animation = walking while injured animation.
* Interpolating between two poses between different points in time.

### Linear interpolation

#### Temporal interpolation
Temporal interpolation identifies two times for two poses, then interpolates the joint positions based on a blend factor.

> Given:
> * \\(N\\) number of joints
> * A beginning pose: \\(P_A^{\text{skel}} = \left\\{ \left( P_A \right)_j \right\\} | _{i=0}^{N-1} \\)
> * A target pose: \\(P_B^{\text{skel}} = \left\\{ \left( P_B \right)_j \right\\} | _{i=0}^{N-1} \\)
>
> The linear interpolation (LERP) between these poses is given by:
> \\[
>   \begin{align}
>       \left(P_{\text{LERP}}\right)_j &= \text{LERP} \left( \left(P_A\right)_j , \left(P_B\right)_j , \beta \right) \\\\
>       &= \left(1 - \beta(t)\right) P_j \left( t_1 \right) + \beta(t) P_j \left(t_2\right)
>   \end{align}
> \\]
>
> Where:
> * Blend factor \\(\beta(t)\\) is determined by
> \\[ \beta(t) = \frac{t-t_1}{t_2 - t_1} \\]
> * \\(t_1\\) is the time that the first pose is shown by itself.
> * \\(t_2\\) is the time that the second pose is shown by itself.
> * \\(t\\) is the time \\(t_1 \le t \le t_2\\) to interpolate along.


We could also use a one-dimensional Bézier curve for an even smoother transition.
* When applied to a clip that is being blended out, this is an _ease-out curve_.
* When applied to a clip that is being blended in, this is an _ease-in curve_.


#### Cross-Fading

One great usage of temporal interpolation is to cross-fade a transition from one pose to the other. 

* Smooth transition
  * Overlay two animations over the top of each other and then cross fade from one animation to the next.  The time overlap that we are cross-fading over defines the \\(t_1\\) and \\(t_2\\).
  * Clips should be looping and their timelines synchronized so that the character's limbs are _roughly_ in the same positions.
* Frozen transition
  * Freeze the first clip in place, then allow the second clip to take over the pose gradually.
  * Works well when the two clips are unrelated and cannot be time-synchronized.


### LERP Blends
Imagining a LERP blend occurring along a timeline can help with visualizing other blending methods.

#### 1D LERP Blending
* Define a range, .e.g, [0, 1], [-1, -1], [-128, 127], or any other.
* Place one or more poses along this range.
* Selecting any blending factor along this range, you can imagine the LERP between the two closest pose points.


#### 2D LERP Blending
* Imagine two 1D LERP blends, perhaps one is a range of the character turning horizontally in a 180 degree arc, and the other blend is the character turning vertically in a 180 degree arc.
* You can then LERP and blend together the combined effect of using the blending factors of both items.
* Graphically, you can imagine this as a 2D grid with two continous but bounded axes.  Moving along one axis animates in one direction and moving along another axis animates in the other direction.
* A big use case for this is to allow you character to look in arbitrary up/down/left/right (and all shades between) directions.

#### Generalized N-clip LERP blending
* Any number of clips can be blended together.  If each clip represents a point on a 2D grid, the space they create (with three clips, they make a triangle, 5 clips makes a pentagon, etc.) can be used to find the blending point between all the involved clips.
* This is done by finding the _barycentric coordinates_ of a given point within the shape created by the clips.
* This works because the LERP blend is effectively a _weighted average_ of the given points.

> \\[ \vec{b} = \alpha \vec{b_0} + \beta \vec{b_1} + \gamma \vec{b_2} \\]
>
> Where
> * \\( \alpha + \beta + \gamma = 1 \\)

## Additive Blending

This almost should be called something other than "blending" because it approaches the task of combining multiple animation clips in way completely different from the LERP discussions above.

A `difference clip` is the difference between two animation clips.  Such `difference clip`s can be added onto other animation clips in order to produce interesting variations.
* A `difference clip` encodes the _changes_ that need to be made to transform one pose into another pose.

Conceptually, a difference clip looks like this

> Conceptual, not actual:
> \\[ D = S - R \\]
>
> Where
> * \\(D\\) is the difference clip
> * \\(S\\) is a source animation clip
> * \\(R\\) is a reference animation clip

Animation clips \\(S\\) and \\(R\\) are actually transform matrices, which you can't really just subtract them.  In actuality, you need to multiply by the inverse.

\\[ D_j = S_j R_j^{-1} \\]

To add a difference pose onto a target pose, you can concatenate the difference and the target transform.

\\[ A_j = D_j T_j = \left( S_j R_j^{-1} \right) T_j \\]

To check that this is correct:

\\[
    \begin{align}
        A_j &= D_j R_j \\\\
            &= S_j R_j^{-1} R_j \\\\
            &= S_j
    \end{align}
\\]


You can use LERP _in addition to_ these difference clips to change how extreme the animation is.

You can still go wrong with additive blending.  Rules of thumb:
* Keep hip rotation sot a minimum in the reference clip
* Should and elbow joints should be in neutral poses in the reference clip to minimize over-rotation.
* Animators should create new difference animations for each core pose.
