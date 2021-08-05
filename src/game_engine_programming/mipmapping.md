# Mipmapping

## Texel Density
A screen is chopped up into thousands of **pixels** on a 2D plane (the monitor).

A texture is also made up of its own "pixels", but for clarity we call them **texels**.

**Texel density is the ratio of texels to pixels** for a given texture displayed on screen.

If we were to view a single texture that took up the entire screen _exactly_, and matched the resolution of the screen _exactly, then each pixel would map to exactly one texel.  In this scenario, texel density is 1.

When you zoom out, the texture gets smaller and it appears smaller on your screen.  Your count of pixels doesn't change (the monitor isn't magically getting bigger or smaller).  **The resolution of the texture** doesn't change either, which means that way more texel data is packed into a single pixel on screen.  Texel density is greater than 1.
* A negative effect of too high texel density means that many texels contribute to the color of a single pixel, which causes something called a _moiré banding pattern_.

When you zoom in, texel density drops below 1, and a single texel becomes larger than a single pixel. If density drops low enough, you'll be able to see the edges of the texels.

Ideally you want to keep texel density at or as close to 1 as possible.  This is done through a technique called **Mipmapping**.


## Mip Levels
Mipmapping involves handing the GPU multiple versions of the texture in decreasing sizes and resolutions in a sequence.  Each iteration is a `mip level` (aka `mipmap`) and is \\(\frac{1}{2}\\) the width and height of its predecessor.

For example, given a 64 x 64 texture, it would have the following mip levels:
* 64 x 64
* 32 x 32
* 16 x 16
* 8 x 8
* 4 x 4
* 2 x 2
* 1 x 1

Once the GPU is aware of these mip levels, it can be configured to select the best mip level which would make texel density as close to 1 as possible.  It performs this selection based on the distance of the triangle from the camera.

`Trilinear filtering` is an advanced technique that you may configure the GPU to use.  It involves selecting the two closest mip levels and blending them together for an even better result.
