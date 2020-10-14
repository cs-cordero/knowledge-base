# Debugging Shaders

See:
* [https://developer.apple.com/documentation/metal/shader_authoring/developing_and_debugging_metal_shaders](https://developer.apple.com/documentation/metal/shader_authoring/developing_and_debugging_metal_shaders)
* [https://www.khronos.org/opengl/wiki/Uniform_(GLSL)/Explicit_Uniform_Location](https://www.khronos.org/opengl/wiki/Uniform_(GLSL)/Explicit_Uniform_Location)

## Troubleshooting
1. Make sure that you enabled logging in your Rust project. The logs can be very useful for debugging.
    * For `env_logger`, you'll need it installed and set up and then you need to `cargo run` with the `RUST_LOG=info` environment variable set.
1. Pay attention to `location={value}` issues. They get kind of interesting when you start sharing arrays.
1. Any `ShaderStage` in your `RenderPipeline` should be enabled for the appropriate Shaders that you expect to use them.
1. Make sure all the data expected to come out of the Vertex shader should actually reach the defined output registers.  Then make sure they translate into the match up with the input registers on the Fragment shader.

## Setting up Rust with XCode Graphics Debugger

* Tested versions
    * macOS Catalina version 10.15.7
    * XCode version 12.0.1 (12A7300)

1. Download and install XCode.
1. Create a new Xcode project.
1. Under the "Other" template category, select "External Build System".
1. Set options for the new project:
    * Use some sensible name for the "Product Name", e.g., `rust-metal-graphics-debugger`.
    * The build tool should be the path to your `rustc`, which is usually `/Users/{you}/.cargo/bin/rustc`.
1. After clicking "Finish", you'll need to select the folder in which to create the new project.  Pick something sensible, e.g., `/Users/{you}/Projects`
    * You don't really need the Git repository, since you won't be doing any Rust development here.
1. At the top left of the window, there is a button that will look like `rust-metal-graphics-debugger > My Mac`, where clicking the left-side will give you a context menu for `Edit Scheme`, `New Scheme`, and `Manage Schemes`.  And clicking the right-side will give you a selection of platforms to target, i.e., `My Mac` or `Any Mac`.
    * Click on the left-side of this button and select `Edit Scheme`.
1. Configure the `Run` scheme.
    * `Info` tab
        * Build Configuration should be `Debug`.
        * Executable should be your Rust binary.  In your Cargo project (outside of Xcode), run `cargo build`, then your binary can be found at `/target/debug/` or `/target/debug/example/` in your Cargo project.
        * Make sure `Debug executable` is checked.
        * Make sure `Me` is selected (instead of `root`)
        * Select Launch `automatically`.
    * `Arguments` tab
        * You might want to set the following environment variables (Optional).
        * `CXX=/usr/bin/clang++`
        * `RUST_BACKTRACE=full`
        * `RUST_LOG=info`
    * `Options` tab
        * Make sure `GPU Frame Capture` is set to `Automatically Enabled`.
        * Click on `Use custom working directory` and set it to your Cargo project root.
    * `Diagnostics` tab
        * Deselect `API Validation` under `Metal`.  We're not writing any direct Metal Shader Language, only what is cross-compiled from SPIR-V, so we don't necessarily need to check this unless we come across a bug from upstream.
1. Click the "Play" button at the top left.  Your app should come up.
1. In the software menu (top of screen), go to `Debug > Capture GPU Frame`.
1. Use the link at the top of this page to Apple docs for how to debug Vertex and Fragment shaders.
