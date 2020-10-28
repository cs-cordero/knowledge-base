## WGPU's TextureFormats

See [https://docs.rs/wgpu/0.6.0/wgpu/enum.TextureFormat.html](https://docs.rs/wgpu/0.6.0/wgpu/enum.TextureFormat.html)

In general, assume linear color space.

## Suffixes

|Suffix|Description|
|:---:|:--- |
|`Unorm`|Float values in range [0, 1] are converted to the [0, 255] unsigned 8-bit range.|
|`Snorm`|Float values in range [0, 1] are converted to the [-127, 127] signed 8-bit range.|
|`Float`|Each channel is a float, usually 16-bit or 32-bit|
|`Uint`|Each channel is assumed already an integer in the unsigned range [0, 255]|
|`Sint`|Each channel is assumed already an integer in the signed range [-127, 127]|
|`Srgb`|Assumes the channel color in range [0, 255] is in Srgb-color space|

## Prefixes

|Prefix|Description|
|:---:|:--- |
|`R8`| Red channel with 8-bits per channel. |
|`R16`| Red channel with 16-bits per channel. |
|`R32`| Red channel with 32-bits per channel. |
|`Rg8`| Red and green channel with 8-bits per channel. |
|`Rg16`| Red and green channel with 16-bits per channel. |
|`Rg32`| Red and green channel with 32-bits per channel. |
|`Rgba8`| Red, green, blue, and alpha channels with 8-bits per channel. |
|`Rgba16`| Red, green, blue, and alpha channels with 16-bits per channel. |
|`Rgba32`| Red, green, blue, and alpha channels with 32-bits per channel. |
|`Bgra8`| Blue, green, red, alpha channels (in that order) with 8-bits per channel. |
|`Rgb10a2`| Red, green, blue channels with 10-bits per channel [0, 1023], plus a 2-bit [0, 3] alpha channel. |
|`Rg11b10`| Red and green channel with 11-bits per channel, plus a blue channel with 10-bits. Typically these channels are floats. |
|`Bc1` through `Bc7`| These are texture compression formats.  The data is assumed to be in a compressed state. |

## Special
|Format|Description|
|:---:|:--- |
|`Depth32Float`|Special depth format with 32-bit float depth.|
|`Depth24Plus`|Special depth with at least 24-bit integer depth.|
|`Depth24PlusStencil8`|Special depth/stencil format with at least 24-bit integer depth and 8-bit integer stencil.|
