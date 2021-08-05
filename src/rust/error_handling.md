# Error Handling

As of today, August 2021, the error handling story for Rust is still being ironed out.  There are lots of crates in contention of becoming the One True Way.

There are two main options for representing errors:
1. Enumeration
    - This enables callers to distinguish between different kinds of errors.
2. One Opaque Error
    - In cases where the user needs to figure out how to resolve the issue, but the _exact_ issue isn't relevant because the application can't meaningfully recover from the specifics of the situation, it could be useful to just give a single error.

When choosing between these, you should consider how the nature of the error will affect what the caller does in response.

### Enumerated Errors

Example:
```rust
pub enum CopyError {
    In(std::io::Error),
    Out(std::io::Error),
}

// std::fmt::Display is required by std::error::Error
impl std::fmt::Display for CopyError { .. }
impl std::error::Error for CopyError { .. }
```

All error types should implement the `std::error::Error` trait.
- The `Error` trait has a method called `Error::source`, which is the mechanism for finding the underlying cause of an error.

All error types should implement the `std::fmt::Display` trait.
- This is required anyway by the `std::error::Error` trait.
- `Display` should give a one-line description of what went wrong that can be easily folded into other error messages.
- It should be lowercase and without trailing punctuation so that it fits with other larger error reports.

All error types should implement the `std::fmt::Debug` trait.
- This is required anyway by the `std::error::Error` trait.
- `Debug` should provide a more descriptive error, with extra information to help track down issues.

Most (nearly all) error types should implement both `Send` and `Sync` so that they can be used in multi-threaded contexts.

Most (nearly all) error types should be `'static`.  Which means they don't hold references to other types unless those references are also `&'static`.

### Opaque Errors
Example (type-erased):
```rust
Box<dyn Error + Send + Sync + 'static>
```

Usage:
```rust
Result<SomeType, Box<dyn Error + Send + Sync + 'static>>
```

Example (struct):
```rust
#[derive(Debug)]
struct MyError(String);

impl Display for MyError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl Error for MyError {}
```

Usage:
```rust
Result<SomeType, MyError>
```

Opaque errors should implement `Send`, `Debug`, `Display`, and `Error`.

Otherwise, the world is your oyster for what type this error will be.

Benefits of making your errors opaque:
1. If your errors are not useful to the end user anyway, then opaque errors avoid forcing you to pass info just to pass info.
1. Type-erased errors often _compose_ nicely.  Functions with a return type of `Box<dyn Error + ...>` can just use `?` almost indiscriminately and they'll get turned into that one common error type.
1. Every variant of an enumerated Error type is part of your API.  If you don't need them, you are just bloating your interface for no benefit.

The `'static` bound on your error types gives you access to **downcasting**.
- Downcasting is taking an item of type T to a more specific, subtype U.
- In Rust, there is a narrow downcasting allowance where you can turn a `dyn Error` into a concrete underlying type when that `dyn Error` was originally of that type.
- This is done using `Error::downcast_ref`, which returns an `Option` and users may match on its success/failure to do different things if the downcast was possible or not.
- `Error::downcast_ref` only works if `T: 'static`

## ?

The `?` operator means "unwrap or return early".  It operates on values of `Result<T, E>`.

The `?` operator performs type conversion using the `From` trait.
- This means that in a function that returns `Result<T, E>` you may use the `?` on any `Result<T, U> where E: From<U>`.

The `?` operator is syntactic sugar for an unstable trait called `Try`.
- `Try` defines a wrapper type whose state is either one where further computation is useful, or one where it is not, e.g., `Result`.  Or monads.
- `Try` generalizes to more than just `Result`.  `Option`, for example, has the exact same pattern so in the future `?` might work with `Option` and maybe others too.

There is an unstable feature feature `try` blocks, where the `?` will `break` out of the block instead of returning from a function early.  This allows you to have cleanup code after the `?`.

```rust
// This is unstable as of August 2021.

fn foo() -> Result<(), Error> {
    let thing = Thing::setup()?;
    let r = try {
        // use thing and ? in here, if error it breaks and sets its error value to r
    };
    thing.cleanup();
    r
}
```




