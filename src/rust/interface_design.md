# Interface Design

There are four principles in writing idiomatic interfaces in Rust.

Interfaces should be:
1. Unsurprising
1. Flexible
1. Obvious
1. Constrained

## Unsurprising Interfaces

Interfaces should be intuitive where if a user had to guess how something would work, they usually guess correctly.

### Things that share similar names/prefixes should work similarly
- This includes sharing similar names with things in the stdlib.
- Users expect `iter` methods to take `&self`.
- Users expect `into_inner` methods to take `self`.
- Users expect `SomethingError` to implement `std::error::Error`.
  
### Structs are expected to implement some traits just out of the box.
- Nearly every type should implement `Debug`.
- Nearly every type should be `Send` and `Sync`, which are already auto-traits.  If your type is NOT, this should be well-documented.
- Most types should have `Clone` and `Default`.
- Many types should have `PartialEq`, `PartialOrd`, `Hash`, `Eq`, and `Ord`.
- For many types it makes sense to have `serde::Serialize` and `serde::Deserialize`.
    - Since `serde` is a third-party crate, it is typical to expose a `serde` feature in your crate that allows users to conditionally compile your library with or without `serde`.
- Few types should implement `Copy`.  Think carefully whether a user would expect your type to be `Copy` and whether it's even possible/feasible/a good idea.
  
### Use blanket trait implementations for ergonomic usage.
- Even if `SomeStruct: Trait`, this does not automatically follow for `&SomeStruct` or `&mut SomeStruct`.
- You should provide blanket implementations as appropriate for `&T where T: Trait`, `&mut T where T: Trait`, and `Box<T> where T: Trait`.
- For any type that can be iterated over, you should implement `IntoIterator` for both `&T` and `&mut T` where applicable.

### Wrapper types, e.g., NewType
- For wrapper types, it's ergonomic to have `Deref<Target = Inner>` and `AsRef`
- If your wrapper type has its own methods and uses `Deref`, avoid taking `&self` or `self` or `&mut self`.  Instead, define static methods.  See, e.g., `Rc::clone(some_rc)`
- In narrow cases, you'll also want to implement `Borrow<T>`, but note that this trait has extra semantic requirements regarding `Hash`, `Eq`, and `Ord`.

## Flexible Interfaces

Interfaces should be "flexible" in the sense that it does not make any _unnecessary_ restrictions on usage and does not promise features that it cannot perform.

Restrictions in Rust are typically function type signatures and trait bounds.
- For example, if you need to access a string, your function could take a `String`, a `&str`, or a `impl AsRef<str>`.

Promises in Rust are typically logic/behavior and return types.
- For example if you ened to return a string, your function could return a `String`, a `Cow<'_, str>`, or a `impl AsRef<str>`.


### Generic arguments can be used to relax restrictions
- Instead of requiring a `MyStruct` or `&MyStruct`, you could accept `T`, which relaxes the type restriction.  You can add some trait bounds to `T` to help it be more useful.
- You pay for making a function generic with harder to read/understand code.
- Generic code results in bigger binaries and longer compile times.
- You have the option of doing dynamic dispatch with `&dyn`, but doing so prevents users from opting out of the dynamic dispatch, which could be a deal-breaker in performance-sensitive code.


### In general, traits should be object-safe
- If a trait is not object-safe, it cannot be made into a trait object using `dyn Trait`.
- If a trait method must take a generic object, you can consider adding a `where Self: Sized` bound to the method which requires a concrete instance of the trait (and not through `dyn Trait`).
- Object safety is part of your public interface.  Adding or removing object safety is a major semantic version change.

### Think carefully about whether your functions, traits, and types should own or borrow its data
- If your code needs to call methods that take `self` or move the data to another thread, it must store the owned data.
    - It should generally make the caller provide owned data.  This makes it upfront known what the cost of using the interface since the caller would have to take care of allocation.
- If your code doesn't need to own the data, it should just take references, (except for tiny `Copy` types, like the integral types).
- The `Cow` type is useful to operate on references if the data allows, or produce an owned value if you need it.

### Custom `Drop` implementations have some pitfalls
- If you place clean-up code as part of a `Drop` implementation, any errors it produces may have to be swallowed because the value is already dropped; there is no way to communicate errors to the user without panicking.
- See also: `async` code, where by the time `Drop` is called, the executor may also be shutting down.
- We can provide an explicit destructor, which is a function that takes ownership of `self` and exposes errors using a return type `Result<_, _>`.
    - Users can use this explicit destructor to gracefully tear down resources.
    - Note that you cannot move resources out of the type inside this destructor, because `Drop::drop` will still be called.
    - Since `Drop::drop` takes `&mut self`, it cannot just call your explicit destructor and ignore its results, since `Drop::drop` doesn't own `self`.
    - Workarounds involve `unsafe`, or using some combination of wrapping things in `Option`s and using `Option::take` to swap data out.

## Obvious Interfaces

Interfaces should make it as easy as possible to understand and as hard as possible to use it incorrectly.

This can be enforced through:
1. Good documentation
1. Type system

### Crash course on documentation
- Document any cases where code will do something unexpected or relies on something beyond what is dictated by the type signature.
- Include end-to-end usage examples on a crate and module level.
- Organize your documentation using modules to group together semantically related items.
    - Use intra-documentation to interlink items. Meaning if `A` talks about `B`, a link to `B` should be right there.
    - Make parts of your interface hidden with `#[doc(hidden)]` in order to not clutter your docs.
- Enrich your docs as much as possible wherever possible, with links to RFCs, blog posts, whitepapers, etc.
    - Use `#[doc(cfg(..))]` to specify that items are available under certain configurations.
    - Use `#[doc(alias = "...")]` to make types and methods discoverable by other names.
    - In top-level docs, point the user to commonly used modules, features, types, traits and methods.

### The type system is your enforcer
- Type systems are self-documenting and misuse-resistant.
- Use `semantic typing` to add types which represent the `meaning` of a value, not just its primitive type.  For example use enums instead of a `boolean`.  Use `struct CreditCardNumber` instead of `u32`.
- Use ZSTs (zero-sized types) to indicate a particular fact is true about an instance of a type. For example:

```rust
struct Grounded;
struct Launched;

struct Rocket<Stage = Grounded> {
    stage: std::marker::PhantomData<Stage>,
}

impl Default for Rocket<Grounded> {}

// Methods only acceptable when rocket is still grounded
impl Rocket<Grounded> {
    pub fn launch(self) -> Rocket<Launched> { .. }
}

// Methods only acceptable when rocket is in the air
impl Rocket<Launched> {
    pub fn accelerate(&mut self) { }
    pub fn decelerate(&mut self) { }
}

// Methods acceptable in either case
impl <Stage> Rocket<Stage> {
    pub fn color(&self) -> Color { .. }
    pub fn weight(&self) -> Kilograms { .. }
}
```

- If a function you are writing accepts a pointer argument, but only uses it if another Boolean argument is `true`, then it's better to combine them into an `enum`, one variant for `MyPointer::false` and another variant for `MyPointer::true(SomePointer)`.
- Make use of the `#[must_use]` annotation.  The compiler issues warnings if the user's code receives an element of the annotated type and doesn't handle it.

## Constrained Interfaces

Always think carefully before you make user-visible changes.  Frequent backward-incompatible changes suck.

Some changes are deceptively backward incompatible, and you might not know it when you make the change.

### Type Modifications are not backwards-compatible
- This involves renaming or removing a public type.
    - Use visibility modifiers, i.e. `pub(crate)` and `pub(in path)` wherever possible to reduce the scope of things that a user can use.
- Adding private fields is not backwards-compatible.
    - Going from zero fields to one private field changes the constructor.
    - Going from some public fields to another private field changes the semantics for Rust's exhaustive pattern matches because `rustc` sees the private fields that users cannot see.
    - Make use of the `#[non_exhaustive]` attribute to mitigate this issue.  This unfortunately makes it so that users cannot rely on exhaustive pattern matches, though.

### Adding/Removing trait implementations is not backwards-compatible
- Users may have created their own implementations of a trait.
    - A new blanket implementation will break Rust's coherence rules.
    - A new implementation for an existing local trait may cause a name conflict.
    - A new implementation for a foreign trait may also break coherence rules if a user already implemented it.
- Removing a trait implementation is a breaking change for obvious reasons:  users may be relying on an implemented method.
- Implementing _new_ traits is never a problem, though, since there is no chance for a user to have a conflicting implementation of the new trait.
- [Sealed traits](https://rust-lang.github.io/api-guidelines/future-proofing.html#sealed-traits-protect-against-downstream-implementations-c-sealed) are great because users may only _use_ them but not _implement_ them, which immediately makes many breaking changes non-breaking.
    - These are commonly used for derived traits, which are traits that provide blanket implementations that implement particular other traits.  Basically: `impl Trait for T where T: SomeOthertrait`.
    - Only seal traits if it makes sense that users should not implement them.
    - Sealed traits are not a feature of the Rust language, but a coding pattern. See above link.
    - Sealed traits should always be documented.

### Re-exports can make dependency upgrades a non-breaking change.
- Any foreign types you expose causes any change to those foreign types to be _also_ a change to your interface.
- It's best to wrap foreign types in the NewType pattern, then expose only the parts of the foreign type that you think are useful.  Don't just blindly implement `Deref`!!

### Auto-Traits add hidden promises to your interface for nearly every type.
- In general, these include `Send`, `Sync`, `Unpin`, `Sized`, and `UnwindSafe`.
- Implementations for these are automatically generated by the compiler but are also automatically _not_ generated if a change you make makes it no longer apply.
- It is a good practice to include a simple test that checks that your type implements the traits the way you expect.

```rust
#[cfg(test)]
mod tests {
    fn is_normal<T: Sized + Send + Sync + Unpin>() {}
    
    #[test]
    fn normal_types() {
        is_normal::<MyType>();
    }
}
```





