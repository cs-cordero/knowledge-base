# User Inputs

See:
* [https://en.wikipedia.org/wiki/Low-pass_filter](https://en.wikipedia.org/wiki/Low-pass_filter)

### Input Types
* Buttons
    * Usually has two discrete states: `up` or `down`, with their meaning being relative to the button itself.
    * Usually `up` is considered the "resting" state, whereas `down` is considered the "active" state.
    * Its state can be held as a single bit, where 0 is the button at rest and 1 is the button in action.
    * Groups of buttons can be represented as an unsigned integer and their states can be queried using bitmasks.
* Analog Axes and Buttons
    * Has a continuous state in one or more axes.
    * For example, a trigger on a controller can sometimes provide analog input allowing you to detect whether the trigger is fully pressed or just slightly pressed.
    * A joystick may also map its _deflection_ on a xy-plane, where (0, 0) is the joystick at rest, (-1, -1) is the joystick being pushed to the lower left and (1, 1) is the joystick being  pushed to the upper right.
    * Can be represented in a number of ways:
        * Signed integer value, e.g., a 16-bit integer has the range -32,768 to 32,767.
        * A floating point
* Relative Axes
    * For when an input does not have an absolute "beginning" or "resting" state, like a button or joystick would.
    * These types of inputs are things like accelerometers and motion controls, e.g., the Nintendo controllers.
    * Multiple accelerometers can detect the orientation of the controller in real-world 3D space.
* Cameras
    * Some inputs use cameras, whether that's infrared or something else.
    * Examples include:
        * Microsoft Kinect
        * PlayStation Camera
        * WiiMote's IR Camera
        
### Receiving Input Signal
Can occur a handful of ways:
* Polling
    * The game engine `poll`s the hardware periodically for its current state.
    * Can occur by reading hardware registers directly, or through a memory-mapped I/O port, or through an abstracted API that does this reading for us.
* Interrupt (Pushing)
    * The device sends information to its host computer only when a change in its state is meaningful.  Otherwise there is no need to stream the same thing over and over.
    * A _hardware interrupt_ causes the CPU to temporarily suspend the program to run a _interrupt service routine_.
    * The most common ISR for games is one that stores the state of the device somewhere and then lets the CPU pick it up when it wants to.
* Bluetooth Protocol
    * For wireless devices.
    * Data can move in both directions, with the host computer receiving input and the controller receiving output from the computer, i.e., to rumble or play a sound, etc.
    
### Game Engine Features
* Dead Zones and Low Pass Filtering
    * For analog controls, the data can be very noisy.  With high precision it can look like the controller is moving even though the player didn't really want it to, i.e., from natural human hand shake.
    * Specify a range from `A to B` in each axis of the analog control to be a "dead zone", inside of which everything is treated as though it might as well be at rest.
    * Even outside of the dead zone, controls may appear choppy and jerky.  You can implement a `low-pass filter` to the raw input data.
    * A low-pass filter specifies a cut-off frequency allows all signals with a frequency below that cut-off to pass through and `attenuates` signals higher than the cut-off frequency.
        * Can be implemented like: `f(t) = (1-a) * lastFramesFilteredInput + a * unfilteredInput`, where `a = delta_time / (RC_constant + delta_time)`
        * Can also be implemented as a moving average over a set number of frames.
* Detect Input Events
    * Button presses
        * Store the current state and the previous state, use bitwise operations to compare and determine which values changed.
        ```rust
        // Just an example
        struct ButtonState {
            curr_state: u32, // allows for 32 buttons
            prev_state: u32,
            changed_to_down_this_frame: u32,
            changed_to_up_this_frame: u32
        }

        impl ButtonState {
            pub fn detectButtonChanges(&mut self) {
                // bitwise XOR to determine the bits that changed. 0 and 1 == 1.
                let button_changes: u32 = &self.curr_state ^ &self.prev_state;

                self.changed_to_down_this_frame = &button_changes & &self.curr_state;
                self.changed_to_up_this_frame = &button_changes & (!&self.curr_state);
            }
        }
        ```
    * Chords
        * A group of buttons that are pressed together at the same time.
        * Watch the states of the two buttons and trigger an event when all of them are down together.
        * Edge cases:
            * If the buttons involved in the chord have their own isolated effects, we have to decide whether those effects should occur or if the chord should take precedence.
            * Humans aren't perfect and they might not be able to press the buttons at _exactly_ the same frame. You may need to introduce a delay between when the button press is "seen" by the game engine, allowing users to combine buttons to form a chord in the delay period.  Or you could trigger the effects of a button press only on _release_.  Or you can begin the single-button move effect and then allow it to be pre-empted by the chord.
    * Gesture detection (button sequences)
        * Keep a brief history of actions performed by the player organized by timestamp.
        * If a subsequent action follows the expected sequence, check the original timestamp to see if it is in the allowable time.  If it is, add to the history and keep detecting, otherwise flush the history and the user will have to begin the gesture again.
* Remapping Controls
    * Edge case: If done in a basic way, the user might accidentally map their joystic to a button or a button to a joystick.  You have to either translate the inputs in a way that is portable or just prevent this from happening.
* Disabling User Input
    * You may want to disable, temporarily or otherwise, certain key presses (or even all user input) at times when certain things are happening on the screen, e.g., a cinematic.
* Context-Sensitive Controls
    * Depending on what is happening on screen at the time, pressing the E button might do different things:  It might open a door or cause the player to jump (e.g., if there is no door).
