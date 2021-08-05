# Animation Constraints

An important aspect of character animation is constraining the movement of objects in the scene in various ways:
* A weapon should be constrained to appear in the hand of a character who is supposed to be holding it.
* Two characters' hands should line up properly when they shake each other's hands.


### Attachments

Object-to-object attachment involves constraining the position and/or orientation of a particular joint on object \\(A\\), \\(J_A\\) such that it coincides with another joint \\(J_B\\) on object \\(B\\).

It can be beneficial to treat this attachment as a parent-child relationship such that when the parent moves, the child moves along with it.

### Interobject Registration

When objects are all interacting with each other it can be useful to have a system that coordinates between all the objects and allows them to animate together.

One way that this system can coordinate this is by using a `reference locator`, which is just a 3D transform located arbitrary anywhere in the scene that interacting animating objects can use as a reference.

### Inverse Kinematics

If a particular joint is not placed correctly since constraints usually use LERP blending and may have some alignment error, you can use inverse kinematics (IK).

IK involves determining the final, desired, position for the `end effector` joint, then IK is applied to a chain of joints up the joint hierarchy  adjust their joint orientations to get the end effector as close to the target as possible.

IK works well when the error difference between the end effector join and its target is relatively small.  For greater distances, it doesn't work that well.

IK does not apply to the orientation of the end effector.


### Other constraints
* Look-at:  Character keeps their head pointed in one direction or twist their body to help them do so.
* Snapping in and out of cover:  Character can take cover behind objects requires the character to snap to and attach to the cover.
