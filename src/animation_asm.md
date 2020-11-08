# Action State Machines
An action state machine is a finite state machine that sits atop the animation pipeline and provides a state-driven animation interface.

Each state corresponds to a blend of simultaneous animation clips.
* For simple states, like `IDLE`, it could be a single full-body looping animation clip.
* For complex states, like `RUNNING`, it could correspond to a 1D blend of animation clips that help you show the character running in a 180-degree arc in front of them.
* For even more complex states, like `RUNNING_AND_SHOOTING`, it could be the 1D blend of animation clips plus additive or partial-skeleton blend nodes to animate the character shooting.

Action State Machines also ensure that the animated object can _transition_ smoothly from state to state.

For a single character that can do multiple things at once, like run, shoot, _and_ speak dialogue at the same time, you might allow multiple ASMs to control a single character.

### Multiple animation clips
When multiple animation clips contribute to the final pose of a character, the engine needs a way to track all of the currently playing clips and how to blend them together.
* Flat weighted average
    * Engine maintains a flat list of animation clips and a flat list of weighting factors to weight the effects from each one.
* Blend trees
    * Each contributing clip is represented by the leaf nodes of a tree.  Interior nodes represent various blending operations being performed on the clips.
    * Multiple blend operations are composed to form action states.
    * Additional blend nodes can represent transient cross-fades.

#### Flat Weighted Average
* Store all active animation clips (clips whose blend weights are nonzero).
* To calculate the final pose of the skeleton at time \\(t\\), extract a pose at the appropriate time index for each of the active animation clips.
* For each joint of the skeleton, calculate an N-point weighted average of the translation vectors, rotation quaternions, and scale factors extracted form the active animations.

\\[ \vec{v_\text{avg}} = \frac{\sum_{i=0}^{N-1} w_i \vec{v_i}}{\sum_{i=0}^{N-1} w_i} \\]

#### Blend Trees
Blend trees can be used to model how animation clips should be blended together.  They represent syntax trees because the leaf nodes are inputs and the internal nodes represent operations.

### Transitions
For some transitions, you can just "pop" from one source state to the target state, with no transitional period.

For other transitions, you can cross-fade from the source state to the target state, and it could generally look good.

For yet other transitions, popping and cross-fading do not apply, e.g., a character in a prone position getting to standing position could not transition with a cross-fade!  To do these kinds of transitions, we need special _transitional states_ that help perform some complex animation while moving from one state to another.

Transition parameters:
* Source state
* Target state
* Transition Type (`POP`, `CROSSFADE`, or `TRANSITIONAL_STATE`)
* Duration
* Ease-in/ease-out curve type (for crossfaded transitions)
* Transition window (allow certain transitions only during some window of time during the source state's animation)

#### Transition Matrix
If you put all the states in an ASM on rows and all the same states on columns, you have a 2D grid that can reflect how one state can transition to another state.  Each grid can hold a `TransitionSpecification` which encodes the above transition parameters.

Keep in mind that this transition matrix will be sparse, since some transitions cannot reach another transition directly.

