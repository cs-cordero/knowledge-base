# Compression
A single joint pose has ten `f32`s of data, or 40 bytes of data:
* Three `f32`s for translation
* Four `f32`s for rotation
* Three `f32`s for scale

Assuming you want to display a 1-second clip sampled at 30 samples per second, this equates to:

\\[
    \begin{align}
        &4 \text{ bytes per f32} \\\\
        &\times 10 \text{ f32s per joint} \\\\
        &\times 30 \text{ samples per second} \\\\
        &= 1200 \text{ bytes per joint per second}
    \end{align}
\\]

This is a lot! Considering a simple skeleton could have 100 joints in it and a modern game could have hundreds of seconds of animation clips.

## Compression Techniques

### Store less data per joint
* If you don't want to support scaling in your game engine (or if most joints don't need it), then omit it entirely, or reduce it to just a single `f32` uniform scaling factor.
* If you don't think a joint should be able to stretch out and shrink in (imagine the neck joint translating away (not just rotating) from the pelvis joint), then you should also just drop it.
* If we can make certain assumptions about the data, we could omit "the last" `f32` of a piece of data.  For example, since the four `f32`s that make up the Quaternion for rotation are usually assumed to be normalized, we could omit the last `f32` and derive it later when we decompress it by subtracting the other components from 1.
* If a pose doesn't change over the course of many samples (it is constant), then a further optimization could be to just store it once with a flag to indicate that it won't change over the course of the sample.

### Quantize `f32`s into `u16`s
* Each component of a quaternion falls in the range [-1, 1].  At a magnitude of 1, the 8-bits that comprise of the exponent bits in a floating point `f32` are all zero.  The remaining 23-bit mantissa provides accuracy to the 7th decimal place.  Quaternions can be effectively encoded with 16 bits of precision, so we are wasting 16 bits per float for our quaternions.
* Quantization is the process of converting a 32-bit IEEE float into an n-bit integer representation.  It is _lossy_.
* Encoding is `f32` to `u16`.
* Decoding is `u16` to `f32`.  This is the part that is an approximated value of the original `f32`.  This process is lossy, since we lose some precision to store the value.
* Quantization involves dividing a range of possible input values to N equally sized intervals.  The `f32` input maps to the integer index of the interval it falls inside.  To decode, we cast the integer index into a `f32` format it refers to, and then shift and scale it back to its original range.
* Rounding the float to the center of the enclosing interval and returning the left-hand side of the interval to which our original value was mapped is the best choice for how to do the quantization.

### Use less samples
* Some animations look fine at 15 samples per second.  Doing this would reduce our animation data size in half.
* If the animation operates in a straight line, LERP could be a good stand-in for removing some samples.

### Use curve-based compression
* Storing animation data as regularly spaced sequence of nonuninform, nonrational B-splines to describe the paths of a joint over time allows channels with a lot of curvature to be encoded using only a few data points.

### Use wavelet compression
Signal processing theory has a technique called _wavelet compression_.

A wavelet is a function whose amplitude oscillates like a wave but with a very short duration.  An animation curve is decomposed into a sum of orthonormal wavelets.

This is an advanced technique, TBD how it works later.

Further reading on wavelet compression:  [Animation Compression: Signal Processing](http://nfrechette.github.io/2016/12/19/anim_compression_signal_processing/)

### Don't use an animation clip at all
* If an animation clip has no chance of being seen, i.e., it only plays on certain levels of your game or if the player has achieved a certain level/class of their character, then don't load the memory at all until it is needed.
* Most games have a core set of animation clips loaded when the game boots.  All other animations are loaded on an as-needed basis.
