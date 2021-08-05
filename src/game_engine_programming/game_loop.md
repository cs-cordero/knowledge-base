# Game Loops and Time

### Common Game Loop Architectures

#### Windows Message Pumps
The Operating System that your game is running on may send messages to your program through a "message pump".  These messages should be handled by your program as soon as possible.  Usually you see this occur for Windows-based games.  All messages from the OS are handled before the next frame is handled.

#### Callback-based
A game engine framework provides an interface for hooking in callbacks that the framework promises to call at specified points during the game loop.

One way to do this is with a thick `Callback` struct with a callback for the `frameStart` and a callback for the `frameEnd` for things that should occur before and after the frame is rendered to the screen.

#### Event-based
A game engine framework provides an interface for defining `EventEmitters` and `EventListeners`.  The listeners are registered with the emitters, who when they emit, they call each of their registered listeners' callbacks.

### Abstract Timeline
Kind of like with coordinate spaces where you can define different kinds that are relative to one another, a timeline is a continuous, 1D axis with an origin at `t=0` and can be at any arbitrary location relative to other abstract timelines.

* Real Time
    * Times measured using the CPU's hi-resolution timer.
* Game Time
    * Usually coincides with _Real Time_ but does not need to.  Game systems could use game time to update itself, which allows us to do things like stop Game Time, slow Game Time, or speed up Game Time.  You'd want to stop time to pause the game, for example.
    * Also useful for debugging.  We could stop the game clock but still keep camera movements working to inspect things.  You could allow time to be controlled by the user in debug mode, stepping time forward in increments on purpose.
* Local Time
    * Animations may have its own concept of a local time, where the beginning of the animation is at `t=0`.
    * If you envision timelines as capable of being mapped from one to the other, local times could, for example be mapped and stretched against a "global" timeline, e.g., Game Time.
    
### Time Measurements
* Frame rate
    * How rapidly the sequence of still 3D frames is presented to the viewer, measured in Hertz (Hz).
* Frame time/Time delta/Delta time/Frame period
    * The amount of time that elapses between frames.
    * This is also the inverse of the _frame frequency_, `T = 1 / f`.  Usually expressed in milliseconds.
* Notes
    * A hi-resolution timer is important because some programming language `time()` functions have the granularity at `seconds`, but you will need it to be at least more granular than `milliseconds`.
    * Usually a hi-res timer gives values in 64-bits, meaning it will overflow once every 100+ years.  A 32-bit timer value will overflow every few seconds.
    * Multi-core CPUs might have separate hi-res timers per core.  And they might drift relative to one another.

### Approaches for taking elapsed time into account
* Old-school
    * Don't worry about it.  Speed is now tied to framerate.
* Use elapsed time
    * Find the delta time by taking a measurement of the global timeframe at the beginning of the frame and a second measurement at the end of the frame.  Subtract them.
    * Doing it like this means that the duration of the current frame won't be seen until the _following_ frame.
* Use a running average of frame time measurements.
    * This reduces the effect that frame spikes may have on your frame time.
* Guarantee the framerate
    * Attempt to _guarantee_ that the delta time will be exactly 16.6ms (for 60 FPS).
    * If we finish earlier than our governed time of 16.6ms, we _wait_ for the remaining duration.
    * If we finish later than our governed time, we _wait_ for one more frame to finish before continuing.
    * This is likely the best option because some systems (such as physics simulations) work better with consistent frames.
    * Consistent frame times enable _record and playback_ features, which is good for both users and debugging.
    * You might have your frame rate governed anyway if VSYNC is enabled.
