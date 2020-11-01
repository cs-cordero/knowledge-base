# Animation Systems
Skinned animation is the most prevalent technique in use today.

A `Skeleton` is constructed from rigid "joints".  A smooth continuous triangle mesh called a `Skin` is bound to the joints of the skeleton.  The `Skin`'s vertices track and move along with the joints of the `Skeleton`.  Each vertex can be weighted to multiple joints.

## Skeleton
A skeleton is made up of a hierarchy of joints.  In storage, they are effectively a n-tree of joints, where one joint is selected as the root.

When a joint is moved or transformed, its children also follow.  For example, the pelvis of a humanoid character might be the root.

In code, a `Skeleton` is usually implemented as a 1-dimensional array of joints where joints are guaranteed to occur before their child joints.

Joints refer to other joints and mesh vertices refer to joints using `joint indices` to query into the `Skeleton` array.

```rust
type JointIndex = usize;

struct Joint {
    inverse_bind_pose: Matrix44,
    debug_name: String,
    parent_joint: JointIndex,
}

struct Skeleton {
    joint_count: u32,
    joints: Vec<Joint>
}
```

## Posing
A `Skeleton` is posed by rotating, translating and possible scaling its joints in arbitrary ways.  The `Pose` of a single joint is defined as that joint's position, orientation, and scale, relative to some frame of reference.  For each joint, this is usually represented in a transform 4x4 matrix or a 4x3 matrix, or a SRT structure, which contains a scale, quaternion, and vector translation.

A single `Pose` is an array of these matrices/SRT structures.  The array should be teh same length as the `Skeleton`, since it has a 1:1 mapping of joints to their pose.

```rust
struct JointPose {
    scale: Vector4,
    rotation: Quaternion,
    translation: Vector4,
}

struct SkeletonPose<'a> {
    skeleton: &'a Skeleton,
    local_pose: Vec<&'a JointPose>
}
```

### Bind Pose
The "Bind Pose", aka "Reference Pose", aka "Rest Pose", aka "T-Pose" is the pose of the 3D mesh prior to being bound to the `Skeleton`.  This means that this is the pose that the mesh would assume if it were rendered as a regular, unskinned triangle mesh without any skeleton at all.

### Joint Space
The _frame of reference_ for each pose is usually with respect to the joint's parent joint.  When done this way, the SRT structure usually is the data structure of choice for the Pose.

The local joint pose is specified relative to the joint's immediate parent.  When the joint pose transform \\(P_j\\) is applied to a point or vector that is expressed in the coordinate system of the joint \\(j\\), the result is that same point or vector expressed in the sapce of the parent joint.

Since a joint pose takes points and vectors from the child joint's space to that of its parent joint, we can write it as \\(\left(P_{C \rightarrow P}\right)_j\\).

### Joint to Model Space
To get the model-space pose of a joint, you can start at the joint in question, then walk all the way up to the root, multiplying the local poses as we go.  The parent space of the root joint should be the model-space.

```rust
struct SkeletonPose<'a> {
    skeleton: &'a Skeleton,
    local_poses: Vec<&'a JointPose>,
    global_poses: Vec<&'a Matrix44>
}
```

## Clips
An _animation clip_ is a a set of fine-grained motions.  Each clip causes the object to perform a single well-defined action.
* Some clips are designed to be looped.
* Some clips are designed to be played once.
* Some clips affect the entire body of the character (like jumping).
* Some clips only affect a part of the body.

### Local Clip Time
Every animation clip has a local timeline, where we define time \\(t\\) such that \\(0 \ge t \ge T\\), where \\(T\\) is the entire duration of the clip.

### Key frames
Animators typically only specify a set of key frames at specific times within the clip, then the engine interpolations between key frames via linear or curve-based interpolation.

Animations can be _time-scaled_ to run faster or slower.  A negative time scale will play the animation in reverse.

Overall, typical time units are in samples of \\(\frac{1}{30}\\) or \\(\frac{1}{60}\\) of a second for game animation.

## Techniques

### Normalized Time
When you want to cross fade between two different animations of different durations, it can be useful to specify a normalized time of \\(u\\) that goes from 0 to 1.  Two different animations can be mapped to this normalized time space, then cross faded to switch between animations.

### Global Timeline
Every character that can be animated has a concept of its "global timeline" \\(\tau\\), which is defined as \\(t = 0\\) when it is first spawned in the game.

Playing an animation clip is mapping that clip's timeline onto the character's global timeline.
* Looping means laying down an infinite number of copies ontot he global timeline.
* Scaling the local timeline bigger means it lasts longer.
* Scaling the local timeline shorter means it goes by more quickly.
* You can even scale it negatively.

To map a local timeline of a clip onto a character's global timeline, you need:
* Global start time \\(\tau_{\text{start}}\\).
* Playback rate \\(R\\).
* Duration \\(T\\).
* Repetition count \\(N\\)

\\[ t = \left(\tau - \tau_{\text{start}}\right) R \\]
\\[ \tau = \tau_{\text{start}} + \frac{1}{R} t \\]

### Animation System
An animation system for a single character can either store local clocks for each clip or store one global clock with the \\(\tau_{\text{start}}\\) recorded for each clip.  Using that information we can figure out the \\(t\\) variable for each animation.

Global clocks can make it easier to map animation clips to a timeline, which helps for synchronization.

```rust
struct JointPose {
    scale: Vector4,
    rotation: Quaternion,
    translation: Vector4,
}

struct AnimationSample<'a> {
    joint_poses: Vec<&'a JointPose>
}

struct AnimationClip<'a> {
    skeleton: &'a Skeleton,
    frames_per_second: f32,
    frame_count: u32,
    animation_samples: Vec<&'a AnimationSample<'a>>,
    is_looping: bool,
}
```

The `JointPose` struct contains the "channels" relevant to an animation.  Some game engines allow there to be meta information in addition to the SRT information shown above.
* For example, at a specific point in the animation, you may want the Animation System to queue a new event (like playing a sound or creating a hit box)
* You may want to store information regarding different texture coordinates that you'd want to be in sync with the animation.

### A Common Setup
```rust
struct Vertex {
    position: Vector3,
    normal: Vector3,
    texture_coordinates: Vector2,
    joint_indices: Vec<usize>,
    joint_weight: Vec<f32>
}

struct Mesh {
    vertex_indices: Vec<usize>,
    /// Meshes own many Vertexes,
    /// each Vertex belongs to one and only one Mesh.
    vertices: Vec<Vertex>,
    /// Skeletons own many Meshes,
    /// Each mesh belongs to one and only one Skeleton.
    skeleton: usize
}

struct SkeletonJoint {
    debug_name: String,
    /// This is a pointer to another SkeletonJoint,
    /// referencing its parent index.
    parent_index: usize,
    inverse_bind_pose: Matrix44,
}

struct Skeleton {
    unique_id: u32,
    joint_count: u32,
    /// Skeleton owns many SkeletonJoints
    /// Each SkeletonJoint belongs to one and only one Skeleton
    joints: Vec<SkeletonJoint>
}

struct SRT {
    /// Can also be a scalar f32
    scale: Vector3,
    rotation: Quaternion,
    translation: Vector3,
}

struct AnimationPose {
    /// AnimationPoses own many SRT per joint.
    poses: Vec<SRT>
}

struct AnimationClip {
    name_id: u32,
    duration: f32,
    pose_samples: Vec<AnimationPose>,
    /// AnimationClips belong to one and only one skeleton_id.
    skeleton_id: u32, 
}
```

