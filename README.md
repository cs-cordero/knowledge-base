# Knowledge Base

These are a collection of random facts and things I know about and/or took notes.

Hosted over at [https://chrisdoescoding.com/kb](https://chrisdoescoding.com/kb).

## Development Notes
* Use the latest `mdbook` binary to render the docs in development.
* This book has overridden the normal `index.hbs` file that comes with `mdbook` to add a _Back to Blog_ button at the top of the documentation.
    * If changes to `mdbook` library occur in later versions, you may need to re-work the files [index.hbs](./theme/index.hbs) and [custom.css](./theme/custom.css).
    * I'd recommend just copying the newest `index.hbs` from mdBook and implementing the button from scratch.

## Dependencies
* [mdBook](https://github.com/rust-lang/mdBook)

## Publishing
Use the `publish.sh` script to `scp` the static files to your remote server.

#### Instructions
1. Make sure `mdbook` is accessible on your `PATH`.
1. Make sure `scp` is accessible on your `PATH`.
1. Make sure your `ssh` is set up to reach your remote server.
1. Run the following command:
```
./publish.sh --scp-loc /path/to/destination/on/remote --hostname /hostname/configured/through/ssh
```

#### Notes
* The hostname should either be the exact IP address of your remote server or a hostname configured in `~/.ssh/config`.
* [MathJax Cheatsheet](https://math.meta.stackexchange.com/questions/5020/mathjax-basic-tutorial-and-quick-reference)

## Author

[Christopher Sabater Cordero](https://chrisdoescoding.com)
